# Tally

**Smart Attendance Intelligence for Students**

![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-blue)

Tally is a modern, cross-platform attendance tracking application built with Flutter. Designed to help students monitor their class attendance, predict future outcomes, and identify potential errors in attendance records.

> **📌 Note:** This app was crafted with a specific workflow in mind, tailored to my personal attendance tracking needs. While it's fully functional and open-source, you may find it works best if your use case aligns with similar requirements. Feel free to fork and customize it to match your own workflow!

---

## ✨ Features

### 📊 **Smart Dashboard**

- Real-time attendance overview with visual progress indicators
- Quick-access class cards with swipe-to-mark functionality
- Upcoming impact predictions to help you stay on track
- Live class indicators with elegant animations

### 📅 **Interactive Calendar**

- Beautiful calendar view with attendance markers
- Day-wise session management
- Quick mark/unmark functionality
- Subject-wise color coding for easy identification
- Comprehensive attendance history

### 🔍 **Intelligent Insights**

- **Anomaly Detection**: Automatically identifies potential errors in attendance records
- **Pattern Analysis**: Detects unusual attendance patterns (e.g., marked absent while other classes were attended)
- **Confidence Scoring**: Each anomaly comes with a confidence level
- **Subject-wise Analysis**: Detailed breakdown of attendance anomalies per subject

### ⚙️ **Flexible Settings**

- Subject management with custom colors
- Timetable configuration
- Theme customization (Light/Dark mode)
- Data backup and restore functionality
- Export attendance data

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.7 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- A device or emulator for testing

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/tally-attendance-tracker.git
   cd tally-attendance-tracker
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture

Tally follows a clean, feature-based architecture:

```
lib/
├── core/               # Core functionality and shared components
│   ├── data/          # Local storage and data services
│   ├── presentation/  # Shared UI components and routing
│   └── theme/         # App theming and styling
├── features/          # Feature modules
│   ├── home/         # Dashboard and quick actions
│   ├── calendar/     # Calendar view and session management
│   ├── insights/     # Anomaly detection and analytics
│   └── settings/     # App configuration and preferences
```

### Key Technologies

- **State Management**: Riverpod
- **Local Storage**: Hive
- **Routing**: GoRouter
- **UI Components**: Material Design 3
- **Date Handling**: Syncfusion Flutter DatePicker
- **Charts**: FL Chart

---

## 📱 Platform Support

- ✅ **Android**
- ✅ **iOS**
- ✅ **Web**
- ✅ **Linux**
- ✅ **macOS**
- ✅ **Windows**

---

## 🎨 Design Philosophy

Tally embraces a **modern, minimal, and elegant** design approach:

- Clean card-based layouts with subtle shadows
- Smooth animations and transitions
- Consistent color theming across platforms
- Responsive design for all screen sizes
- Intuitive gestures (swipe-to-mark, pull-to-refresh)

---

## 🔧 Configuration

### Adding Subjects

1. Navigate to Settings → Manage Subjects
2. Tap the '+' button
3. Enter subject details and choose a color
4. Set your target attendance percentage

### Setting Up Timetable

1. Go to Settings → Timetable
2. Add class timings for each day
3. Assign subjects to time slots

---

## 📊 Data Management

### Backup

- Automatic local backup using Hive
- Manual export to JSON format
- Cloud backup support (coming soon)

### Privacy

- All data stored locally on your device
- No external servers or data collection
- Complete control over your information

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for design guidelines
- All open-source contributors whose packages made this possible

---

## 📧 Contact

For questions, suggestions, or feedback, please open an issue on GitHub.

---

**Made with ❤️ using Flutter**
