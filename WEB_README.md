# Survival Planner - Flutter Web Application

## Overview
This is a complete Flutter web application for State of Survival game tools, featuring:

### Features
- **HiveMap Editor**: Interactive alliance map editor with bear trap placement and member management
- **Resource Calculators**: Building costs, troop training, gear upgrades, and event calculations  
- **Cloud Sync**: Supabase integration for saving and sharing data
- **Responsive Design**: Works on desktop and mobile browsers
- **Real-time Data**: Live updates and collaboration features

### Project Structure
```
lib/
├── main.dart                    # Main app entry point with routing
├── hivemap/                     # HiveMap editor components
│   ├── main.dart               # HiveMapEditor widget and related classes
│   ├── models.dart             # Data models for map objects
│   ├── grid_renderer.dart      # Custom grid rendering
│   └── ...                     # Supporting files
├── survival_planner_calculator/ # Calculator tools
│   ├── main.dart               # Calculator app entry point
│   ├── building_page.dart      # Building calculators
│   ├── troops_page.dart        # Troop calculators
│   ├── chief_page.dart         # Chief gear calculators
│   └── ...                     # More calculator pages
├── services/                   # Shared services (auth, data)
├── generated/                  # Localization files
└── ...                         # Supporting folders
```

## Building for Web

### Prerequisites
- Flutter SDK (3.8.1+)
- Chrome browser for testing

### Build Commands
```bash
# Get dependencies
flutter pub get

# Run in development mode
flutter run -d chrome

# Build for production
flutter build web --release

# Deploy script (Windows)
deploy_web.bat
```

### Deployment
The built files are in `build/web/` and can be deployed to:
- Static hosting (Netlify, Vercel, GitHub Pages)
- Firebase Hosting
- Any web server supporting SPAs

### Configuration
- Supabase credentials are in `lib/main.dart`
- Firebase Analytics configured in `web/index.html`
- App metadata in `web/manifest.json`

## Development Notes

### Web-Specific Features
- Progressive Web App (PWA) ready
- Responsive layout with mobile support
- File download/upload functionality
- Local storage for offline capability
- URL routing for deep linking

### Key Dependencies
- `supabase_flutter`: Backend services
- `file_picker`: File operations
- `shared_preferences`: Local storage
- `url_launcher`: External links
- `image`: Image processing

### Architecture
- **Main App**: Landing page with feature selection
- **HiveMap**: Full-featured map editor with grid rendering
- **Calculators**: Collection of game calculation tools
- **Services**: Shared authentication and data services

This application successfully runs as a Flutter web app with full functionality preserved.