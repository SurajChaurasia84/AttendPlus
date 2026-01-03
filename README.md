# 📚 Attend Plus

Attend Plus is a modern digital attendance management app built with Flutter and Firebase,
designed for schools and colleges.
It helps teachers take attendance quickly, manage students efficiently,
and view detailed attendance reports with an excellent user experience.

---

## 🚀 Why Attend Plus?

Traditional attendance methods are slow, error-prone, and hard to analyze.
Attend Plus solves this by offering:

- One-tap attendance marking
- Clean and intuitive UI
- Monthly and global attendance reports
- Secure authentication
- Real-time cloud storage

---

## ✨ Features

### 🧑‍🏫 Teacher Dashboard
- Personalized greeting
- Total classes vs submitted attendance
- Today’s scheduled classes
- Quick access to actions

### ✅ Attendance Management
- Take attendance by class
- Present / Absent toggle
- Attendance submission lock (no duplicate entries)
- Disabled submit button after submission

### 👨‍🎓 Student Management
- Add, edit, delete students
- Roll number validation
- Multiple student entry support

### 📊 Reports and Analytics
- Monthly attendance view
- Attendance percentage per student
- Color-coded performance
- Global reports across all classes

### 🔔 UX Feedback
- Loading indicators on buttons
- Snackbar success and error messages
- Disabled actions to prevent mistakes

---

## 🎨 UX and UI Principles Used

- Clarity  
  Cards, tiles, and sections are used to separate information clearly.

- Feedback  
  Loading spinners and snackbars inform users about actions.

- Consistency  
  Same button styles, card layouts, and colors across the app.

- Error Prevention  
  Disabled buttons, form validations, and submission locks.

- Responsiveness  
  Flexible layouts using Expanded, Spacer, and MediaQuery.

---

## 📱 Screens UX Flow

### 1 Welcome Screen
- Fixed-height image (no layout jump)
- Centered text content
- Smooth transition to Login screen

### 2 Home Screen
- Overview cards at the top
- Quick action buttons
- Real-time data from Firebase

### 3 Attendance Screen
- Student list with Present / Absent toggle
- Present and Absent count shown on top-left
- Submit button disabled after submission
- Button text shows “Attendance already submitted”

### 4 Reports Screen
- Monthly navigation (previous / next month)
- Attendance percentage with color indicators
- Scrollable sections for each class

---

## 🛠 Tech Stack

- Flutter (Dart)
- Firebase Authentication
- Cloud Firestore
- Shared Preferences
- Material Design
- StreamBuilder and Stateful Widgets
- Android platform (iOS ready)

---

## 📂 Project Structure

lib/
  screens/
    auth/
      login_screen.dart
      signup_screen.dart
    home/
      home_screen.dart
    attendance/
      attendance_screen.dart
    reports/
      reports_screen.dart
    students/
      add_student_screen.dart
  widgets/
    animated_gradient_button.dart
  services/
    firebase_service.dart
  main.dart

---

## 🔒 Security

- Firebase Authentication for secure login
- Attendance submission locked per date
- Duplicate roll numbers prevented
- Firestore rules to protect data

---

## 🌱 Future Enhancements

- Dark mode
- Push notifications
- Export attendance to PDF or Excel
- Student login panel
- Multi-language support

---

## 👨‍💻 Author

Suraj Chaurasia  
Flutter and Firebase Developer  
India 🇮🇳

---

⭐ If you like this project, please give it a star on GitHub ⭐
