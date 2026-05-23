# 📈 Habit Tracker Pro

A modern Habit Tracker mobile application built using **Flutter** that helps users build consistency, track habits, monitor progress, and stay motivated using daily reminders and analytics.

---

## 🚀 Features

✅ Create and manage habits  
✅ Track daily habit completion  
✅ Persistent local storage using SharedPreferences  
✅ Daily notification reminders  
✅ Progress statistics dashboard  
✅ Interactive custom line chart  
✅ Track progress by:
- 7 Days
- 14 Days
- Weekly
- Monthly

✅ Dark Mode Support  
✅ Material 3 UI  
✅ Clean and responsive Flutter design

---

## 📱 App Preview

### Main Features

- Habit Creation
- Daily Tracking
- Progress Dashboard
- Custom Analytics Chart
- Reminder Notifications
- Local Data Saving

---

## 🛠️ Technologies Used

| Technology | Purpose |
|------------|---------|
| Flutter | Mobile App Development |
| Dart | Programming Language |
| SharedPreferences | Local Storage |
| Flutter Local Notifications | Daily Reminders |
| Timezone Package | Scheduled Notifications |
| Material 3 | Modern UI Design |

---

## 📂 Project Structure

```text
lib/
│
├── main.dart
│
├── NotificationService
├── HabitData Model
├── Dashboard UI
├── Custom Line Chart
└── Local Storage Logic
```

---

## ⚙️ Installation

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/habit-tracker-pro.git
```

---

### 2. Open Project

```bash
cd habit-tracker-pro
```

---

### 3. Install Packages

```bash
flutter pub get
```

---

### 4. Run App

Android:

```bash
flutter run
```

---

## 📦 Dependencies

```yaml
flutter_local_notifications
timezone
shared_preferences
```

---

## 🔥 How the App Works

### 1. Habit Creation
Users can create custom habits and choose icons.

Examples:

- Workout
- Reading
- Meditation
- Coding
- Health Goals

---

### 2. Local Data Storage

The app stores habit progress using:

**SharedPreferences**

This means:

✅ No internet required  
✅ Data saved locally  
✅ Progress remains after app restart

---

### 3. Daily Habit Tracking

Users can:

- Mark habits completed
- Toggle completion status
- Navigate between dates
- View previous progress

Future dates are restricted to maintain accurate tracking.

---

### 4. Smart Notification System

The app schedules **5 daily reminders** using:

**Flutter Local Notifications + Timezone**

Reminder Times:

- 9 AM
- 12 PM
- 3 PM
- 6 PM
- 9 PM

Motivational reminders help maintain streaks and avoid breaking habits.

---

### 5. Analytics Dashboard

The dashboard displays:

📊 Days Tracked  
📊 Weeks Active  
📊 Months Active

This gives users a clear overview of their consistency.

---

### 6. Custom Line Chart

The application includes a **custom-built line chart** using Flutter CustomPainter.

Users can analyze:

- Last 7 Days
- Last 14 Days
- Weekly Progress
- Monthly Progress

The chart dynamically updates based on completed habits.

---

## 🎯 Learning Outcomes

This project demonstrates:

- Flutter State Management
- Local Storage
- Notification Scheduling
- Custom Painter Graphics
- Mobile UI Design
- Data Visualization
- Habit Tracking Logic
- Material 3 Development

---

## 🌙 UI Features

- Material 3 Design
- Dark Theme Support
- Responsive Layout
- Smooth User Experience
- Minimal and Modern Interface

---

## 🔐 Privacy

This application:

✅ Works offline  
✅ Stores data locally  
✅ Does not collect user information  
✅ No cloud storage required

---

## 🤝 Contributing

Contributions and improvements are welcome.

Fork the repository and submit a pull request.

---

## ⭐ Support

If you found this project useful, please consider giving it a **Star ⭐** on GitHub.

---

## 👨‍💻 Developer

Built with ❤️ using Flutter and Dart.
