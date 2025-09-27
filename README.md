# Survival Planner Website

A Flutter web application with Supabase backend integration for survival planning and data management.

## Features

- 🔐 **Authentication**: User registration and login with Supabase Auth
- 📱 **Responsive Design**: Works on desktop and mobile browsers
- 🔄 **Real-time Data**: Live data synchronization with Supabase
- 🌐 **Web Optimized**: Built specifically for web deployment
- 💾 **Database Integration**: Full CRUD operations with Supabase

## Technologies Used

- **Flutter Web**: Cross-platform UI framework
- **Supabase**: Backend-as-a-Service for database, auth, and real-time features
- **Dart**: Programming language
- **Provider**: State management (ready to use)

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Chrome browser for testing
- Supabase account

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd surivalplanner_website
flutter pub get
```

### 2. Supabase Configuration

1. Create a new project at [supabase.io](https://supabase.io)
2. Get your project URL and anon key from the API settings
3. Update `lib/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Database Setup (Optional)

Create tables in your Supabase dashboard as needed. The app includes example service methods that you can customize.

### 4. Run the Application

```bash
# For development
flutter run -d chrome

# For production build
flutter build web
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart     # Supabase initialization
├── screens/
│   ├── auth_screen.dart         # Login/Register screen
│   └── home_screen.dart         # Main dashboard
├── services/
│   ├── auth_service.dart        # Authentication logic
│   └── database_service.dart    # Database operations
└── main.dart                    # App entry point
```

## Available VS Code Tasks

- **Run Flutter Web**: Starts the development server
- Use `Ctrl+Shift+P` → "Tasks: Run Task" → "Run Flutter Web"

## Key Features Explained

### Authentication
- Email/password authentication via Supabase Auth
- Automatic session management
- Secure sign-up and sign-in flows

### Database Operations
The `DatabaseService` provides methods for:
- `getAllRecords()` - Fetch all records from a table
- `insertRecord()` - Add new records
- `updateRecord()` - Modify existing records
- `deleteRecord()` - Remove records
- `subscribeToTable()` - Real-time updates

### Real-time Updates
Subscribe to database changes:
```dart
DatabaseService.subscribeToTable('your_table', (payload) {
  // Handle real-time updates
});
```

## Deployment

### Build for Production
```bash
flutter build web --release
```

The built files will be in `build/web/` directory.

### Deploy Options
- **Supabase Hosting**: Direct integration
- **Netlify**: Drag and drop the `build/web` folder
- **Vercel**: Connect your Git repository
- **Firebase Hosting**: Use Firebase CLI

## Environment Variables

For production, consider using environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Development Tips

1. **Hot Reload**: Save files to see changes instantly
2. **Debug Console**: Use browser dev tools for debugging
3. **Flutter Inspector**: Use VS Code's Flutter Inspector for UI debugging
4. **Supabase Dashboard**: Monitor database and auth in real-time

## Troubleshooting

### Common Issues

1. **CORS Errors**: Add your domain to Supabase allowed origins
2. **Auth Issues**: Check your Supabase auth configuration
3. **Build Errors**: Run `flutter clean` and `flutter pub get`

### Useful Commands

```bash
# Check for issues
flutter analyze

# Update dependencies
flutter pub upgrade

# Clean build cache
flutter clean
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Check the [Flutter documentation](https://docs.flutter.dev/)
- Visit [Supabase documentation](https://supabase.io/docs)
- Open an issue in this repository
