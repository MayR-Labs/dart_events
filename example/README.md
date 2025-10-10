# Mayr Events Example

This example demonstrates how to use the `mayr_events` package in a Flutter application.

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## What This Example Shows

### 1. Defining Events

Events are simple data classes that extend `MayrEvent`:

```dart
class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;
  const UserRegisteredEvent(this.userId, this.email);
}
```

### 2. Creating Listeners

Listeners handle events by extending `MayrListener<T>`:

```dart
class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    await EmailService.sendWelcome(event.email);
  }
}
```

### 3. Setting Up the Event System

Use `MayrEventSetup` to register listeners and configure hooks:

```dart
class MyAppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  }
}
```

### 4. Initializing in main()

```dart
void main() async {
  await MyAppEvents().init();
  runApp(MyApp());
}
```

### 5. Firing Events

```dart
await MayrEvents.instance.fire(
  UserRegisteredEvent('user123', 'user@example.com'),
);
```

## Features Demonstrated

- ✅ Multiple listeners for the same event
- ✅ Async listener execution
- ✅ Once-only listeners
- ✅ beforeHandle hook for logging
- ✅ onError hook for error handling
- ✅ Clean separation of concerns

## Console Output

When you run the example and interact with it, you'll see detailed logs in the console showing:
- Which listeners are being triggered
- When events are fired
- Execution flow and timing
