import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 1. NOTIFICATION SERVICE
class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    tz.initializeTimeZones();
    final settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
  }

  static Future schedule5DailyReminders(int currentStreak) async {
    List<int> notificationHours = [9, 12, 15, 18, 21];

    for (int i = 0; i < notificationHours.length; i++) {
      await _notifications.zonedSchedule(
        i,
        'Habit Reminder 🔔',
        'Don\'t break your $currentStreak day streak!',
        _nextInstanceOfHour(notificationHours[i]),
        const NotificationDetails(
          android: AndroidNotificationDetails('habit_channel', 'Habits',
              importance: Importance.max, priority: Priority.high),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfHour(int hour) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

// 2. DATA MODEL
class HabitData {
  final String habitName;
  final IconData habitIcon;
  Map<DateTime, bool> dailyCompletion;

  HabitData({
    required this.habitName,
    required this.habitIcon,
    Map<DateTime, bool>? dailyCompletion,
  }) : dailyCompletion = dailyCompletion ?? {};

  // Convert to JSON
  Map<String, dynamic> toJson() {
    Map<String, String> completionMap = {};
    dailyCompletion.forEach((date, completed) {
      completionMap[date.toIso8601String().split('T')[0]] = completed.toString();
    });
    
    return {
      'habitName': habitName,
      'habitIcon': habitIcon.codePoint,
      'dailyCompletion': completionMap,
    };
  }

  // Create from JSON
  factory HabitData.fromJson(Map<String, dynamic> json) {
    Map<DateTime, bool> completion = {};
    Map<String, dynamic> completionMap = json['dailyCompletion'] ?? {};
    
    completionMap.forEach((dateStr, value) {
      DateTime date = DateTime.parse(dateStr);
      completion[date] = value == 'true';
    });

    return HabitData(
      habitName: json['habitName'] ?? '',
      habitIcon: IconData(
        json['habitIcon'] ?? Icons.star.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      dailyCompletion: completion,
    );
  }
}

// 3. MAIN APP
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyHabitApp());
}

// Custom Line Chart Widget
class LineChartCustom extends StatelessWidget {
  final List<HabitData> habits;
  final DateTime today;
  final String period;

  const LineChartCustom({
    required this.habits,
    required this.today,
    required this.period,
    super.key,
  });

  List<int> _getDataPoints() {
    List<int> dataPoints = [];
    
    if (period == "7days") {
      for (int i = 6; i >= 0; i--) {
        DateTime date = today.subtract(Duration(days: i));
        int completedCount = habits.where((h) => h.dailyCompletion[date] ?? false).length;
        dataPoints.add(completedCount);
      }
    } else if (period == "14days") {
      for (int i = 13; i >= 0; i--) {
        DateTime date = today.subtract(Duration(days: i));
        int completedCount = habits.where((h) => h.dailyCompletion[date] ?? false).length;
        dataPoints.add(completedCount);
      }
    } else if (period == "weeks") {
      for (int i = 11; i >= 0; i--) {
        DateTime startDate = today.subtract(Duration(days: i * 7));
        DateTime endDate = startDate.add(const Duration(days: 7));
        int weeklyCount = 0;
        for (var habit in habits) {
          bool hasCompletion = habit.dailyCompletion.entries.any((e) =>
              e.key.isAfter(startDate.subtract(const Duration(days: 1))) &&
              e.key.isBefore(endDate) &&
              e.value);
          if (hasCompletion) weeklyCount++;
        }
        dataPoints.add(weeklyCount);
      }
    } else if (period == "months") {
      for (int i = 11; i >= 0; i--) {
        int year = today.year;
        int month = today.month - i;
        if (month <= 0) {
          month += 12;
          year -= 1;
        }
        int monthlyCount = 0;
        for (var habit in habits) {
          bool hasCompletion = habit.dailyCompletion.entries.any((e) =>
              e.key.year == year &&
              e.key.month == month &&
              e.value);
          if (hasCompletion) monthlyCount++;
        }
        dataPoints.add(monthlyCount);
      }
    }
    
    return dataPoints;
  }

  List<String> _getLabels() {
    List<String> labels = [];
    
    if (period == "7days") {
      for (int i = 6; i >= 0; i--) {
        DateTime date = today.subtract(Duration(days: i));
        labels.add(_getShortDayName(date));
      }
    } else if (period == "14days") {
      for (int i = 13; i >= 0; i--) {
        DateTime date = today.subtract(Duration(days: i));
        labels.add(date.day.toString());
      }
    } else if (period == "weeks") {
      for (int i = 11; i >= 0; i--) {
        DateTime date = today.subtract(Duration(days: i * 7));
        labels.add("W${date.day}");
      }
    } else if (period == "months") {
      for (int i = 11; i >= 0; i--) {
        int month = today.month - i;
        if (month <= 0) month += 12;
        labels.add("M$month");
      }
    }
    
    return labels;
  }

  String _getShortDayName(DateTime date) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    List<int> dataPoints = _getDataPoints();
    List<String> labels = _getLabels();
    int maxValue = habits.length > 0 ? habits.length : 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
        child: SizedBox(
          width: dataPoints.length > 1 ? 100 + (dataPoints.length * 50) : 300,
          height: 200,
          child: Stack(
            children: [
              // Chart
              CustomPaint(
                painter: LineChartPainter(
                  dataPoints: dataPoints,
                  maxValue: maxValue,
                  pointCount: dataPoints.length,
                  chartHeight: 120,
                ),
                size: Size.infinite,
              ),
              // Labels positioned under points
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(labels.length, (index) {
                      return SizedBox(
                        width: 50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              labels[index],
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<int> dataPoints;
  final int maxValue;
  final int pointCount;
  final double chartHeight;

  LineChartPainter({
    required this.dataPoints,
    required this.maxValue,
    required this.pointCount,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.orange.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 0.5;

    double chartTop = 20;
    double chartBottom = size.height - 45;
    double pointSpacing = (size.width - 40) / (pointCount - 1).clamp(1, 100);

    // Draw grid lines
    for (int i = 0; i <= maxValue; i++) {
      double y = chartBottom - (i * (chartHeight / maxValue));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (dataPoints.isEmpty) return;

    // Calculate points
    List<Offset> points = [];
    for (int i = 0; i < dataPoints.length; i++) {
      double x = 20 + (i * pointSpacing);
      double y = chartBottom - (dataPoints[i] / maxValue * chartHeight).clamp(0, chartHeight);
      points.add(Offset(x, y));
    }

    // Draw filled area
    if (points.length > 1) {
      Path path = Path();
      path.moveTo(points.first.dx, chartBottom);
      for (var point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, chartBottom);
      path.close();
      canvas.drawPath(path, fillPaint);

      // Draw line
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw points
    for (var point in points) {
      canvas.drawCircle(point, 3.5, paint);
      canvas.drawCircle(point, 3.5, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // Draw axis
    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartBottom), Offset(size.width, chartBottom), axisPaint);
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}

class MyHabitApp extends StatelessWidget {
  const MyHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.orange),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.orange),
      home: const HabitTrackerDashboard(),
    );
  }
}

class HabitTrackerDashboard extends StatefulWidget {
  const HabitTrackerDashboard({super.key});

  @override
  State<HabitTrackerDashboard> createState() => _HabitTrackerDashboardState();
}

class _HabitTrackerDashboardState extends State<HabitTrackerDashboard> {
  static const List<IconData> availableIcons = [
    Icons.code,
    Icons.fitness_center,
    Icons.book,
    Icons.favorite,
    Icons.self_improvement,
  ];

  List<HabitData> habits = [];
  late DateTime selectedDate;
  String chartPeriod = "7days"; // "7days", "14days", "weeks", "months"

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    _loadHabits();
  }

  // Load habits from SharedPreferences
  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getStringList('habits') ?? [];
    
    if (habitsJson.isEmpty) {
      // Load default habits on first launch
      setState(() {
        habits = [
          HabitData(habitName: "Workout", habitIcon: Icons.fitness_center),
          HabitData(habitName: "Read 30 Mins", habitIcon: Icons.book),
          HabitData(habitName: "Meditate", habitIcon: Icons.self_improvement),
        ];
      });
      _saveHabits();
    } else {
      setState(() {
        habits = habitsJson.map((jsonStr) {
          return HabitData.fromJson(jsonDecode(jsonStr));
        }).toList();
      });
    }
    NotificationService.schedule5DailyReminders(calculateTotalTrackedDays());
  }

  // Save habits to SharedPreferences
  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = habits.map((habit) => jsonEncode(habit.toJson())).toList();
    await prefs.setStringList('habits', habitsJson);
  }

  DateTime get today => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int calculateTotalTrackedDays() {
    Set<DateTime> trackedDays = {};
    for (var habit in habits) {
      habit.dailyCompletion.forEach((date, completed) {
        if (completed) trackedDays.add(date);
      });
    }
    return trackedDays.length;
  }

  int calculateWeeksTracked() {
    Set<int> weeks = {};
    for (var habit in habits) {
      for (var entry in habit.dailyCompletion.entries) {
        if (entry.value) {
          int weekOfYear = _getWeekNumber(entry.key);
          weeks.add(weekOfYear);
        }
      }
    }
    return weeks.length;
  }

  int calculateMonthsTracked() {
    Set<String> months = {};
    for (var habit in habits) {
      for (var entry in habit.dailyCompletion.entries) {
        if (entry.value) {
          String monthKey = "${entry.key.year}-${entry.key.month}";
          months.add(monthKey);
        }
      }
    }
    return months.length;
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(date.toIso8601String().split('T')[0].replaceAll('-', ''));
    return ((dayOfYear) / 7).floor();
  }

  List<bool> getLast7DaysCompletion() {
    List<bool> completion = [];
    for (int i = 6; i >= 0; i--) {
      DateTime date = today.subtract(Duration(days: i));
      bool hasAnyHabitDone = habits.any((habit) => habit.dailyCompletion[date] ?? false);
      completion.add(hasAnyHabitDone);
    }
    return completion;
  }

  Widget _buildPeriodButton(String label, String period) {
    bool isSelected = chartPeriod == period;
    return ElevatedButton(
      onPressed: () => setState(() => chartPeriod = period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey.withOpacity(0.2),
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _addHabit() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String newName = "";
        IconData newIcon = Icons.star;

        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Create New Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setDialogState(() => newName = value);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Habit name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Icon:'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: availableIcons.map((icon) {
                      return IconButton(
                        icon: Icon(icon, color: newIcon == icon ? Colors.orange : Colors.grey),
                        onPressed: () => setDialogState(() => newIcon = icon),
                      );
                    }).toList(),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: newName.isEmpty ? null : () {
                    setState(() {
                      habits.add(HabitData(habitName: newName, habitIcon: newIcon));
                    });
                    _saveHabits();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Create"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentStreak = calculateTotalTrackedDays();
    int weeksTracked = calculateWeeksTracked();
    int monthsTracked = calculateMonthsTracked();
    List<bool> last7Days = getLast7DaysCompletion();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Habit Tracker Pro"),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Statistics Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.withOpacity(0.1),
              width: double.infinity,
              child: Column(
                children: [
                  const Text(
                    "Your Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            "$currentStreak",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const Text("Days Tracked", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "$weeksTracked",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const Text("Weeks Active", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            "$monthsTracked",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const Text("Months Active", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Line Chart - Customizable Period
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Habit Tracking History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPeriodButton("7 Days", "7days"),
                      _buildPeriodButton("14 Days", "14days"),
                      _buildPeriodButton("Weeks", "weeks"),
                      _buildPeriodButton("Months", "months"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Chart
                  Card(
                    color: Colors.grey.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 200,
                        child: LineChartCustom(
                          habits: habits,
                          today: today,
                          period: chartPeriod,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Date Navigation (Prevent Future)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1))),
                  ),
                  Text(
                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: selectedDate == today
                        ? null
                        : () {
                            DateTime nextDate = selectedDate.add(const Duration(days: 1));
                            if (nextDate.isBefore(today) || nextDate == today) {
                              setState(() => selectedDate = nextDate);
                            }
                          },
                  ),
                ],
              ),
            ),

            // Habits List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: List.generate(habits.length, (index) {
                  final habit = habits[index];
                  bool isDone = habit.dailyCompletion[selectedDate] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: isDone ? Colors.orange.withOpacity(0.15) : null,
                    child: ListTile(
                      leading: Icon(habit.habitIcon, color: isDone ? Colors.orange : Colors.grey),
                      title: Text(
                        habit.habitName,
                        style: TextStyle(
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isDone,
                        onChanged: (val) {
                          setState(() {
                            habit.dailyCompletion[selectedDate] = val!;
                          });
                          _saveHabits();
                          NotificationService.schedule5DailyReminders(calculateTotalTrackedDays());
                        },
                      ),
                      onTap: () {
                        setState(() {
                          habit.dailyCompletion[selectedDate] = !isDone;
                        });
                        _saveHabits();
                        NotificationService.schedule5DailyReminders(calculateTotalTrackedDays());
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getShortDayName(DateTime date) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[date.weekday - 1];
  }
}
