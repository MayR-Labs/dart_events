# Quick Start Guide

Get up and running with mayr_events in 5 minutes!

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mayr_events: ^0.0.1
```

Then run:

```bash
flutter pub get
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

### Step 3: Set Up the Event System

Create `config/app_events.dart`:

```dart
import 'package:mayr_events/mayr_events.dart';
import '../events/user_events.dart';
import '../listeners/welcome_email_listener.dart';

class AppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    // Register all your listeners here
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  }
  
  @override
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
    // Optional: Log before each listener executes
    print('[Event] ${event.runtimeType} → ${listener.runtimeType}');
  }
  
  @override
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
    // Optional: Handle errors globally
    print('[Error] ${event.runtimeType}: $error');
  }
}
```

### Step 4: Initialize in main()

Update your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'config/app_events.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the event system
  await AppEvents().init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayr Events Demo',
      home: HomeScreen(),
    );
  }
}
```

### Step 5: Fire Events

In any screen or widget:

```dart
import 'package:flutter/material.dart';
import 'package:mayr_events/mayr_events.dart';
import '../events/user_events.dart';

class RegisterScreen extends StatelessWidget {
  Future<void> _registerUser(String email) async {
    // Your registration logic here
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Fire the event
    await MayrEvents.instance.fire(
      UserRegisteredEvent(userId, email),
    );
    
    print('User registered and event fired!');
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _registerUser('user@example.com'),
      child: Text('Register User'),
    );
  }
}
```

## That's It!

You now have a working event system! When a user registers:
1. The `UserRegisteredEvent` is fired
2. All registered listeners (like `SendWelcomeEmailListener`) execute
3. Each listener can perform its task independently

## What's Next?

### Add More Listeners

You can have multiple listeners for the same event:

```dart
class TrackAnalyticsListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    // Track user registration in analytics
    await Analytics.track('user_registered', {
      'user_id': event.userId,
    });
  }
}

// Register it
@override
void registerListeners() {
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  MayrEvents.on<UserRegisteredEvent>(TrackAnalyticsListener());
}
```

### Use Once-Only Listeners

For listeners that should only run once:

```dart
class ShowWelcomeTutorialListener extends MayrListener<AppLaunchedEvent> {
  @override
  bool get once => true;  // Only runs once
  
  @override
  Future<void> handle(AppLaunchedEvent event) async {
    // Show welcome tutorial
  }
}
```

### Run in Isolate for Heavy Work

For CPU-intensive tasks:

```dart
class ProcessDataListener extends MayrListener<DataReceivedEvent> {
  @override
  bool get runInIsolate => true;  // Runs in separate isolate
  
  @override
  Future<void> handle(DataReceivedEvent event) async {
    // Heavy computation that won't block UI
  }
}
```

## Common Patterns

### Order Processing

```dart
// Event
class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;
  const OrderPlacedEvent(this.orderId, this.total);
}

// Listeners
class ProcessPaymentListener extends MayrListener<OrderPlacedEvent> {
  Future<void> handle(OrderPlacedEvent event) async {
    await PaymentService.process(event.orderId);
  }
}

class SendOrderConfirmationListener extends MayrListener<OrderPlacedEvent> {
  Future<void> handle(OrderPlacedEvent event) async {
    await EmailService.sendOrderConfirmation(event.orderId);
  }
}

class UpdateInventoryListener extends MayrListener<OrderPlacedEvent> {
  Future<void> handle(OrderPlacedEvent event) async {
    await InventoryService.updateStock(event.orderId);
  }
}
```

### User Authentication

```dart
// Events
class UserLoggedInEvent extends MayrEvent {
  final String userId;
  const UserLoggedInEvent(this.userId);
}

class UserLoggedOutEvent extends MayrEvent {
  final String userId;
  const UserLoggedOutEvent(this.userId);
}

// Listeners
class TrackLoginListener extends MayrListener<UserLoggedInEvent> {
  Future<void> handle(UserLoggedInEvent event) async {
    await Analytics.track('login', {'user_id': event.userId});
  }
}

class ClearCacheListener extends MayrListener<UserLoggedOutEvent> {
  Future<void> handle(UserLoggedOutEvent event) async {
    await CacheService.clear();
  }
}
```

## Tips

1. **Organize your code:**
   ```
   lib/
   ├── events/
   │   ├── user_events.dart
   │   ├── order_events.dart
   │   └── app_events.dart
   ├── listeners/
   │   ├── user/
   │   │   ├── send_welcome_email_listener.dart
   │   │   └── track_analytics_listener.dart
   │   └── order/
   │       ├── process_payment_listener.dart
   │       └── send_confirmation_listener.dart
   └── config/
       └── app_events.dart
   ```

2. **Test your listeners individually:**
   ```dart
   test('SendWelcomeEmailListener sends email', () async {
     final listener = SendWelcomeEmailListener();
     await listener.handle(UserRegisteredEvent('123', 'test@example.com'));
     
     // Verify email was sent
   });
   ```

3. **Use descriptive event names:**
   - Good: `UserRegisteredEvent`, `OrderPlacedEvent`, `PaymentCompletedEvent`
   - Avoid: `UserEvent`, `OrderEvent`, `PaymentEvent`

4. **Keep listeners focused:**
   - Each listener should do one thing well
   - Use multiple listeners instead of one that does everything

## Getting Help

- 📖 [Full API Documentation](API.md)
- 🧪 [Testing Guide](TESTING.md)
- 🤝 [Contributing Guide](CONTRIBUTING.md)
- 💡 [Design Document](DESIGN.md)
- 📱 [Example App](example/)

## Next Steps

1. Check out the [example app](example/) for a complete working implementation
2. Read the [API documentation](API.md) for all available features
3. Join the community and contribute!

Happy coding! 🚀
