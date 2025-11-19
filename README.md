# FSP Client

Flutter frontend application for the FSP (Financial Strategy Portfolio) project.

## Features

- 📊 Portfolio composition management
- 📈 Backtest parameter configuration
- 📉 Visual results with charts
- 🔄 Real-time API integration with backend server

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- Running FSP Server on `http://localhost:8080`

## Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run the application

```bash
flutter run
```

Or select a device in your IDE and run.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── portfolio.dart                 # Data models
├── services/
│   ├── api_service.dart              # API client
│   └── portfolio_provider.dart       # State management
├── screens/
│   ├── home_screen.dart              # Main portfolio configuration screen
│   └── backtest_result_screen.dart   # Results visualization screen
└── widgets/                           # Reusable widgets (if needed)
```

## Usage

1. **Configure Portfolio**: Add stocks with their symbols and weights
2. **Set Parameters**: Choose start/end dates, initial capital, and DCA amount
3. **Run Backtest**: Click "Run Backtest" to execute
4. **View Results**: See performance metrics and charts

## Backend Integration

This app connects to the FSP Server API:
- `POST /api/backtest/run` - Run portfolio backtest
- `POST /api/insight/analyze` - Analyze insights
- `POST /api/insight/ai` - Generate AI insights

Make sure the server is running before using the app.

## Development

### Add new dependencies

```bash
flutter pub add package_name
```

### Run tests

```bash
flutter test
```

### Build for production

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web

# Windows
flutter build windows
```

## Dependencies

- `provider` - State management
- `http` - HTTP client
- `fl_chart` - Charts and graphs
- `intl` - Internationalization and formatting
