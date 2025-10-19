# Quick Start Guide

Get up and running with mayr_events in 5 minutes!

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mayr_events: ^2.0.0
```

Then run:

```bash
dart pub get
```

## 5-Minute Tutorial

### Step 1: Define an Event

Create a new file `events/user_events.dart`:

```dart
import 'package:mayr_events/mayr_events.dart';

class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;
  
  const UserRegisteredEvent(this.userId, this.email);
}
```

### Step 2: Create a Listener

Create a new file `listeners/welcome_email_listener.dart`:

```dart
import 'package:mayr_events/mayr_events.dart';
import '../events/user_events.dart';

class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    // Send welcome email
    print('Sending welcome email to ${event.email}');
    
    // Simulate email sending
    await Future.delayed(Duration(seconds: 1));
    
    print('Welcome email sent!');
  }
}
```

### Step 3: Set Up Events

Create `config/events_setup.dart`:

```dart
import 'package:mayr_events/mayr_events.dart';
import '../events/user_events.dart';
import '../listeners/welcome_email_listener.dart';

void setupEvents() {
  // Register listeners
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  
  // Add global hooks (optional)
  MayrEvents.beforeHandle('logger', (event, listener) async {
    print('[Event] ${event.runtimeType} → ${listener.runtimeType}');
  });
  
  MayrEvents.onError('error_logger', (event, error, stack) async {
    print('[Error] ${event.runtimeType}: $error');
  });
}
```

### Step 4: Initialize in main()

Update your `main.dart`:

```dart
import 'config/events_setup.dart';

void main() async {
  // Initialize the event system
  setupEvents();
  
  runApp(MyApp());
}
```

### Step 5: Fire Events

Anywhere in your app:

```dart
import 'package:mayr_events/mayr_events.dart';
import 'events/user_events.dart';

Future<void> registerUser(String email) async {
  final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  
  // Fire the event
  await MayrEvents.fire(
    UserRegisteredEvent(userId, email),
  );
  
  print('User registered and event fired!');
}
```

## Advanced Features

### Event-Level Hooks

Events can define their own hooks:

```dart
class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;
  
  const UserRegisteredEvent(this.userId, this.email);
  
  @override
  Future<void> Function(MayrEvent, MayrListener)? get beforeHandle =>
      (event, listener) async {
        print('About to handle user registration');
      };
}
```

### Keyed Handlers

Manage handlers with unique keys:

```dart
// Add multiple handlers
MayrEvents.beforeHandle('logger', logCallback);
MayrEvents.beforeHandle('metrics', metricsCallback);

// Remove specific handler
MayrEvents.removeBeforeHandler('logger');
```

### ShouldHandle Validation

Control when listeners execute:

```dart
MayrEvents.shouldHandle('validator', (event) {
  // Return false to skip listener execution
  if (event is UserRegisteredEvent) {
    return event.userId.isNotEmpty;
  }
  return true;
});
```

### Once-Only Listeners

Listeners that run only once:

```dart
class FirstTimeSetupListener extends MayrListener<AppLaunchedEvent> {
  @override
  bool get once => true;

  @override
  Future<void> handle(AppLaunchedEvent event) async {
    print('This runs only once');
  }
}
```

## What's Next?

- Check out the [README](README.md) for complete API documentation
- Review the [example app](example/) for a working implementation
- See [MIGRATION.md](MIGRATION.md) if upgrading from v1.x

## Need Help?

- 📚 [Full Documentation](README.md)
- 🐛 [Report Issues](https://github.com/MayR-Labs/dart_events/issues)
- 💬 [Discussions](https://github.com/MayR-Labs/dart_events/discussions)
