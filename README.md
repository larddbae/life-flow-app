<h1 align="center">
  <br>
  🌊 LifeFlow
  <br>
</h1>

<p align="center">
  <strong>Your all-in-one personal productivity and finance ecosystem — beautifully minimal, powerfully local.</strong>
</p>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  </a>
  <a href="https://pub.dev/packages/sqflite">
    <img src="https://img.shields.io/badge/SQLite-Local%20DB-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite">
  </a>
  <a href="https://pub.dev/packages/flutter_riverpod">
    <img src="https://img.shields.io/badge/Riverpod-State%20Mgmt-00BCD4?style=for-the-badge&logo=riverpod&logoColor=white" alt="Riverpod">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge" alt="MIT License">
  </a>
</p>

<p align="center">
  <a href="#-key-features">Features</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-roadmap">Roadmap</a> •
  <a href="#-about-the-author">About</a>
</p>

---

## 📸 Screenshots

> Replace the placeholders below with your actual app screenshots.

<table align="center">
  <tr>
    <td align="center">
      <img src="https://via.placeholder.com/300x600/0D0D0D/FFFFFF?text=Today+Nexus" width="220" alt="Today Nexus Dashboard"/>
      <br/>
      <sub><b>Today Nexus</b></sub>
    </td>
    <td align="center">
      <img src="https://via.placeholder.com/300x600/0D0D0D/FFFFFF?text=Finance+Manager" width="220" alt="Finance Manager"/>
      <br/>
      <sub><b>Finance Manager</b></sub>
    </td>
    <td align="center">
      <img src="https://via.placeholder.com/300x600/0D0D0D/FFFFFF?text=Project+Board" width="220" alt="Project Kanban Board"/>
      <br/>
      <sub><b>Project Board</b></sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://via.placeholder.com/300x600/0D0D0D/FFFFFF?text=Routines" width="220" alt="Modular Routines"/>
      <br/>
      <sub><b>Modular Routines</b></sub>
    </td>
    <td align="center">
      <img src="https://via.placeholder.com/300x600/0D0D0D/FFFFFF?text=Reflection" width="220" alt="Deep Reflection"/>
      <br/>
      <sub><b>Deep Reflection</b></sub>
    </td>
    <td align="center">
      <img src="https://via.placeholder.com/300x600/0D0D0D/FFFFFF?text=Analytics" width="220" alt="Monthly Analytics"/>
      <br/>
      <sub><b>Monthly Analytics</b></sub>
    </td>
  </tr>
</table>

---

## ✨ Key Features

LifeFlow is organized into five distinct yet interconnected modules, each designed to handle a specific dimension of your life.

### 🧭 Today Nexus — Your Command Center
The intelligent dashboard that gives you a pulse on your day at a glance.

- **Dynamic, Time-Aware Greetings** — Contextual welcome messages that shift based on the time of day (morning, afternoon, evening).
- **Real-Time Energy Logging** — A 5-level battery input system to log your current energy state, feeding directly into monthly analytics.
- **Daily Budget Gauge** — Automatically calculates your *safe-to-spend* budget by factoring in your monthly budget, current transactions, and the remaining days in the month.
- **Quick-Check Task View** — Surfaces your highest-priority tasks for a frictionless morning review.

### 💸 Finance Manager — Full Financial Clarity
A lightweight but complete personal finance tracker built for discipline.

- **Income & Expense Tracking** — Log transactions with amounts, categories, and detailed notes.
- **Dynamic Monthly Budgets** — Full CRUD support for setting and adjusting monthly budget targets.
- **Wishlist with Funding Logic** — Track savings goals and visualize progress toward each wish based on your surplus.
- **Paginated Transaction History** — Browse your complete financial history with category-based filtering.

### 📋 Project Board — Kanban for Your Goals
A Notion-inspired Kanban board that brings focus to your personal and professional projects.

- **Project-Based Task Management** — Organize tasks under distinct projects for clear context separation.
- **Priority Badges** — Assign Low, Medium, or High priority to each task with a visible color-coded badge.
- **Due Dates & Date Filtering** — Attach due dates to tasks and use the horizontal Date Navigation Bar to filter your board by any specific day.
- **Full CRUD Task Lifecycle** — Create, edit, and delete tasks directly from the board with a polished slide-up sheet.

### 🔁 Modular Routines — Build Lasting Habits
A habit tracking system designed around consistency and long-term pattern recognition.

- **Customizable Habit Library** — Define habits with custom schedules (daily or specific weekdays).
- **30-Day Activity Heatmap** — Visualize your consistency over the past 30 days with a GitHub-style contribution graph.
- **Month-to-Month Navigation** — Browse historical completion data for any past month.
- **Categorized Habit Groups** — Habits are organized by schedule type (Daily vs. Custom Days) for easier management.

### 🔍 Deep Reflection — Monthly Intelligence Report
Your personal monthly retrospective, automated.

- **Productivity vs. Energy Charts** — A custom `CustomPainter` dual-axis chart correlating your daily task completion rate against logged energy levels.
- **Automated Metrics** — Auto-calculated habit completion percentage, savings rate, and longest active habit streak.
- **Qualitative Journal History** — Browse past journal entries from any month via a filterable bottom sheet.
- **Reactive Month Navigation** — All charts, metrics, and history update live as you navigate between months.

---

## 🏗️ Architecture

LifeFlow is built on a clean, scalable **Feature-First** architecture, inspired by the principles of Domain-Driven Design.

### 📁 Folder Structure

```
lib/
├── core/                     # Shared, app-wide infrastructure
│   ├── database/
│   │   └── database_helper.dart   # Singleton SQLite initializer & migrations
│   ├── models/                    # Pure Dart data models (POJOs)
│   │   ├── budget.dart
│   │   ├── daily_log.dart
│   │   ├── habit.dart
│   │   ├── project.dart
│   │   ├── project_task.dart
│   │   ├── transaction.dart
│   │   ├── wishlist.dart
│   │   └── ...
│   ├── repositories/              # Data access layer (SQL ↔ Model)
│   │   ├── budget_repository.dart
│   │   ├── habit_repository.dart
│   │   ├── transaction_repository.dart
│   │   └── ...
│   ├── providers/                 # Global Riverpod providers
│   └── theme/                    # AppTheme, colors, typography
│
├── features/                 # Self-contained feature modules
│   ├── today_nexus/          # Dashboard
│   ├── finance/              # Finance manager
│   ├── projects/             # Kanban board
│   ├── routines/             # Habit tracker
│   └── reflection/           # Analytics & journaling
│
└── main.dart                 # App entry point & ProviderScope
```

> Each `features/<module>/` directory follows the same internal structure:
> `screens/` → `widgets/` → `providers/` → `state/`

### ⚡ State Management — Riverpod with AsyncNotifiers

All business logic is encapsulated in `AsyncNotifier` and `Notifier` classes, exposing immutable state to the UI layer. This ensures:

- **Zero prop-drilling** — UI widgets consume providers directly via `ref.watch()`.
- **Predictable side-effects** — Mutations go through `ref.read(provider.notifier).method()`.
- **Lazy loading** — Providers are only initialized when first consumed.

```dart
// Example: Watching the daily budget calculation
final budget = ref.watch(dailyBudgetProvider);

return budget.when(
  data: (value) => BudgetGlanceCard(safeToSpend: value),
  loading: () => const ShimmerCard(),
  error: (e, _) => const ErrorWidget(),
);
```

### 🗄️ Data Layer — SQLite with Repository Pattern

All persistence is handled locally via `sqflite`, abstracted behind a clean Repository interface. The `DatabaseHelper` is a singleton that manages table creation, schema versioning, and migrations.

```
UI Layer (Widgets)
      ↕  ref.watch / ref.read
State Layer (AsyncNotifier / Notifier)
      ↕  repository.method()
Repository Layer (SQL Queries)
      ↕  DatabaseHelper.instance.database
SQLite (Local on-device storage)
```

This separation ensures the UI never holds raw SQL logic, and repositories remain independently testable.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.x`
- An Android emulator, iOS simulator, or physical device

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/adelardtyanmunandar/life-flow.git
   cd life-flow
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   ```bash
   flutter run
   ```

> **Note:** LifeFlow uses only local SQLite storage — no backend or API keys are required. It runs entirely offline out of the box.

---

## 🗺️ Roadmap

LifeFlow is actively evolving. Here's a glimpse of what's planned:

| Status | Feature |
|--------|---------|
| ✅ | Today Nexus Dashboard with real-time data |
| ✅ | Full Finance CRUD with budget & wishlist |
| ✅ | Kanban Project Board with date filtering |
| ✅ | Routine Habit Tracker with 30-day heatmap |
| ✅ | Deep Reflection with custom analytics charts |
| 🔜 | **Cloud Sync** — Optional backup via Firebase or Supabase |
| 🔜 | **Desktop Support** — Adaptive layout for Windows & macOS |
| 🔜 | **Widget Support** — Home screen widgets for Today Nexus |
| 🔜 | **Data Export** — CSV / PDF export for Finance reports |
| 🔜 | **Notifications & Reminders** — Scheduled habit reminders |
| 🔜 | **Multi-Profile** — Support for multiple user profiles locally |
| 🔜 | **Theme Customization** — User-selectable accent colors |

---

## 👨‍💻 About the Author

<table>
  <tr>
    <td align="center" width="120">
      <img src="https://via.placeholder.com/100/0D0D0D/FFFFFF?text=AT" width="80" style="border-radius: 50%;" alt="Adelard Tyan Munandar"/>
    </td>
    <td>
      <strong>Adelard Tyan Munandar</strong><br/>
      Software Engineering Student at <strong>SMKN 1 Lumajang</strong><br/><br/>
      A passionate creative front-end developer with a deep interest in crafting elegant, user-centric digital experiences. LifeFlow was born from a desire to solve real personal productivity challenges with a beautifully minimal interface — built entirely with Flutter and a love for clean architecture.<br/><br/>
      <a href="https://github.com/adelardtyanmunandar">GitHub</a> •
      <a href="https://linkedin.com/in/adelardtyanmunandar">LinkedIn</a>
    </td>
  </tr>
</table>

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ and Flutter by <strong>Adelard Tyan Munandar</strong>
  <br/>
  <sub>If you find this project useful, please consider giving it a ⭐</sub>
</p>
