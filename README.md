# 📱 Productivity Suite — Android (Flutter)

> A comprehensive, premium personal productivity suite for Android.
> Built with **Flutter + Dart** using a futuristic dark glassmorphism design language.

[![GitHub](https://img.shields.io/badge/GitHub-VARSHAN69-purple?style=flat-flat&logo=github)](https://github.com/VARSHAN69)
[![Platform](https://img.shields.io/badge/Platform-Android-green?style=flat-flat&logo=android)](https://flutter.dev)
[![Framework](https://img.shields.io/badge/Framework-Flutter-blue?style=flat-flat&logo=flutter)](https://flutter.dev)

This app brings all your personal dashboard, daily planning, habit tracking, focus timing, budget details, calendar events, secure credentials, clipboard history, and file organizer into one seamless, localized, secure, and gorgeous application.

---

## ✨ Features & Architecture

This application consists of **9 powerful integrated modules**, each sporting a premium, visual-first glassmorphism look with smooth navigation:

1. **🏠 Interactive Dashboard**
   - Welcomes you with dynamic personal greeting & greeting illustration.
   - Shows real-time statistics of completed tasks, habits, and budgets.
   - Features a daily motivational quote with animation.
2. **✅ Task Manager**
   - High-fidelity lists with priority indicators (High, Medium, Low).
   - Bottom-sheet task editor.
   - Filter by status (All, Active, Completed) and instant search.
3. **📝 Rich Notes**
   - Premium notes manager with multi-column grid/list layout.
   - Separate full-screen Markdown-ready note editor page.
   - Auto-saves every 800ms of typing inactivity.
4. **⚡ Habit Tracker**
   - Dynamic grid displaying streak lengths and goal tracking.
   - 7-day visual interactive heatmap of habit completion history.
   - Custom emoji icon selector and accent colors.
5. **⏱ Pomodoro Timer**
   - Animated circular countdown timer.
   - Configurable modes (Work, Short Break, Long Break).
   - Auto-logging of completed focus rounds with settings configuration.
6. **📊 Budget Tracker**
   - Visual representation of monthly income, expenses, and net balance.
   - Dynamic transaction ledger sorted chronologically.
   - Categorized transaction entry (Food, Transport, Rent, Salary, Bills, etc.).
7. **📅 Interactive Calendar**
   - Fluid grid calendar representing days of the month.
   - Quick-add events pinned to specific days with title, description, and times.
   - Visual dots indicating days with scheduled events.
8. **🔒 Secure Password Vault**
   - Master password gate with custom cryptographic generation.
   - Save vault items with titles, usernames, passwords, and websites.
   - Tap to copy credentials directly to clipboard.
9. **📋 Clipboard Manager**
   - Real-time text clipboard grabber and manager.
   - Search/categorize past clip history.
   - Single-tap to re-copy elements or delete clips.

---

## 🛠 Tech Stack & Configuration

- **SDK Version:** Flutter `>=3.0.0 <4.0.0` (Dart 3.x support)
- **State Management:** `provider` for unified app-wide state.
- **Local Persistence:** Local JSON-based SharedPreferences data store in `utils/data_store.dart`. Works completely offline with instant reads/writes.
- **Typography:** Sleek fonts dynamically pulled using `google_fonts`.

---

## 📂 Project Structure

```
lib/
├── main.dart             # Main entry point, setting theme & orientation locks
├── utils/
│   ├── app_theme.dart    # Central styling system (Color palettes, Gradients, Shadows)
│   └── data_store.dart   # JSON-based shared preferences store
└── screens/
    ├── home_screen.dart       # Bottom navigation container with smooth transitions
    ├── dashboard_screen.dart  # Home analytics and greeting screen
    ├── tasks_screen.dart      # Task management CRUD screen
    ├── notes_screen.dart      # Note manager and note editor screen
    ├── habits_screen.dart     # Habit tracker and heatmap screen
    ├── pomodoro_screen.dart   # Pomodoro countdown and session screen
    ├── budget_screen.dart     # Budget ledger and dynamic entry screen
    ├── calendar_screen.dart   # Event planner and grid calendar screen
    ├── passwords_screen.dart  # Secure password generator and vault screen
    └── clipboard_screen.dart  # Local clipboard manager and search screen
```

---

## 🚀 Getting Started

1. **Prerequisites:**
   Install [Flutter SDK](https://docs.flutter.dev/get-started/install) on your system.

2. **Clone the repository:**
   ```bash
   git clone https://github.com/VARSHAN69/productivity-suite-android.git
   cd productivity-suite-android
   ```

3. **Get dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   Connect an Android device or start an emulator, then execute:
   ```bash
   flutter run
   ```

---

## 🎨 Design System

Built on a luxurious **futuristic dark scheme**:
- **Backgrounds:** `#0A0A0F` to `#12121A` dark mesh.
- **Cards (Glassmorphism):** Transparent cards with frosted glass effect, border outlines, and subtle glow.
- **Accents:** Neon magenta `#FF007F`, purple gradient `#8A2BE2`, and electric cyan `#00F5FF`.
