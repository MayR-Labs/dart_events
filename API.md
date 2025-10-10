# API Documentation

Complete API reference for the mayr_events package.

## Table of Contents

- [MayrEvent](#mayrevent)
- [MayrListener](#mayrlistener)
- [MayrEvents](#mayrevents)
- [MayrEventSetup](#mayreventsetup)

---

## MayrEvent

Base class for all events in the system.

### Definition

```dart
abstract class MayrEvent {
  const MayrEvent();
}
```

### Usage

Create custom events by extending `MayrEvent`:

```dart
class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;
  
  const UserRegisteredEvent(this.userId, this.email);
}

class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;
  
  const OrderPlacedEvent(this.orderId, this.total);
}
```

### Guidelines

- **Keep events immutable** - Use `final` fields and `const` constructors
- **One responsibility** - Each event should represent one thing that happened
- **Descriptive names** - Use past tense (e.g., `UserRegistered`, not `RegisterUser`)
- **Include relevant data** - Pass all necessary information in the event

---

## MayrListener

Base class for event listeners.

### Definition

```dart
abstract class MayrListener<T extends MayrEvent> {
  const MayrListener();
  
  bool get once => false;
  bool get queued => true;
  bool get runInIsolate => false;
  
  Future<void> handle(T event);
}
```

### Properties

#### `once`

Whether the listener should run only once per lifecycle.

- **Type:** `bool`
- **Default:** `false`
- **When `true`:** Listener is automatically removed after first execution

```dart
class TrackAppLaunchListener extends MayrListener<AppLaunchedEvent> {
  @override
  bool get once => true;  // Runs only once
  
  @override
  Future<void> handle(AppLaunchedEvent event) async {
    // Track app launch
  }
}
```

#### `queued`

Whether the listener should be queued for later execution.

- **Type:** `bool`
- **Default:** `true`
- **Status:** Currently not implemented (placeholder for future feature)

#### `runInIsolate`

Whether the listener should run in a separate isolate.

- **Type:** `bool`
- **Default:** `false`
- **When `true`:** Listener executes in isolate via `Isolate.run()`

```dart
class HeavyComputationListener extends MayrListener<DataProcessEvent> {
  @override
  bool get runInIsolate => true;  // Runs in separate isolate
  
  @override
  Future<void> handle(DataProcessEvent event) async {
    // Heavy computation that won't block UI
  }
}
```

**Note:** When using isolates, the listener and event must not capture any context from the main isolate.

### Methods

#### `handle(T event)`

Main method that handles the event.

- **Parameters:**
  - `event` - The event instance to handle
- **Returns:** `Future<void>`
- **Called:** When the associated event is fired

```dart
class SendEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    await EmailService.send(
      to: event.email,
      subject: 'Welcome!',
      body: 'Hello ${event.userId}!',
    );
  }
}
```

---

## MayrEvents

The central event bus. Manages listeners and fires events.

### Singleton Instance

```dart
MayrEvents.instance
```

Access the singleton instance of the event bus.

### Methods

#### `listen<T>(MayrListener<T> listener)`

Registers a listener for a specific event type.

```dart
MayrEvents.instance.listen<UserRegisteredEvent>(
  SendWelcomeEmailListener(),
);
```

#### `on<T>(MayrListener<T> listener)` (static)

Shorthand for `instance.listen()`.

```dart
MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
```

#### `fire<T>(T event)`

Fires an event to all registered listeners.

```dart
await MayrEvents.instance.fire(
  UserRegisteredEvent('user123', 'user@example.com'),
);
```

- Executes all listeners for the event type
- Handles errors via `onError` if set
- Removes once-only listeners after execution
- Returns when all listeners complete

#### `remove<T>(MayrListener<T> listener)`

Removes a specific listener.

```dart
final listener = MyListener();
MayrEvents.on<MyEvent>(listener);

// Later...
MayrEvents.instance.remove<MyEvent>(listener);
```

#### `removeAll<T>()`

Removes all listeners for an event type.

```dart
MayrEvents.instance.removeAll<UserRegisteredEvent>();
```

#### `clear()`

Removes all listeners for all event types.

```dart
MayrEvents.instance.clear();
```

Useful for:
- Testing
- Resetting state
- Clean shutdown

#### `listenerCount<T>()`

Returns the number of listeners for an event type.

```dart
final count = MayrEvents.instance.listenerCount<UserRegisteredEvent>();
print('$count listeners registered');
```

#### `hasListeners<T>()`

Checks if any listeners are registered for an event type.

```dart
if (MayrEvents.instance.hasListeners<UserRegisteredEvent>()) {
  print('Listeners are registered');
}
```

### Properties

#### `beforeHandle`

Hook called before each listener handles an event.

```dart
MayrEvents.instance.beforeHandle = (event, listener) async {
  print('[${DateTime.now()}] ${listener.runtimeType} handling ${event.runtimeType}');
};
```

Use cases:
- Logging
- Performance monitoring
- Middleware-like behavior

#### `onError`

Global error handler for listener failures.

```dart
MayrEvents.instance.onError = (event, error, stack) async {
  print('[ERROR] ${event.runtimeType} failed: $error');
  await ErrorReporter.report(error, stack);
};
```

- Called when a listener throws an exception
- Execution continues with next listener
- If not set, errors are silently ignored

---

## MayrEventSetup

Base class for application-level event configuration.

### Definition

```dart
abstract class MayrEventSetup {
  const MayrEventSetup();
  
  void registerListeners();
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {}
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {}
  Future<void> init() async;
}
```

### Methods

#### `registerListeners()`

Register all event-listener bindings.

```dart
@override
void registerListeners() {
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  MayrEvents.on<UserRegisteredEvent>(TrackAnalyticsListener());
  MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());
}
```

Called during `init()`.

#### `beforeHandle(event, listener)`

Hook executed before each listener handles an event.

```dart
@override
Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
  logger.info('Processing ${event.runtimeType} with ${listener.runtimeType}');
  
  // Start performance timer
  _timers[listener] = Stopwatch()..start();
}
```

Default implementation does nothing.

#### `onError(event, error, stack)`

Global error handler for listener failures.

```dart
@override
Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
  logger.error('Error in ${event.runtimeType}: $error');
  await ErrorReportingService.report(error, stack);
  
  // Send alert for critical events
  if (event is CriticalEvent) {
    await AlertService.sendAlert('Critical event handler failed');
  }
}
```

Default implementation does nothing.

#### `init()`

Initializes the event system.

```dart
void main() async {
  await MyAppEvents().init();
  runApp(MyApp());
}
```

This method:
1. Calls `registerListeners()`
2. Sets up `beforeHandle` hook
3. Sets up `onError` hook

### Example

```dart
class MyAppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    // User events
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
    MayrEvents.on<UserRegisteredEvent>(TrackUserAnalyticsListener());
    
    // Order events
    MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());
    MayrEvents.on<OrderPlacedEvent>(SendConfirmationEmailListener());
    
    // System events
    MayrEvents.on<AppLaunchedEvent>(InitializeServicesListener());
  }
  
  @override
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ${listener.runtimeType} → ${event.runtimeType}');
  }
  
  @override
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
    print('[ERROR] ${event.runtimeType}: $error');
    
    // Log to error tracking service
    await Sentry.captureException(
      error,
      stackTrace: stack,
      hint: Hint.withMap({'event': event.runtimeType.toString()}),
    );
  }
}
```

---

## Best Practices

### Event Design

1. **Keep events simple and focused**
   ```dart
   // Good
   class UserRegisteredEvent extends MayrEvent {
     final String userId;
     const UserRegisteredEvent(this.userId);
   }
   
   // Avoid
   class UserEvent extends MayrEvent {
     final String action; // 'register', 'login', 'logout', etc.
     final String userId;
     const UserEvent(this.action, this.userId);
   }
   ```

2. **Use descriptive, past-tense names**
   ```dart
   // Good
   class OrderPlacedEvent extends MayrEvent { }
   
   // Avoid
   class PlaceOrderEvent extends MayrEvent { }
   class OrderEvent extends MayrEvent { }
   ```

### Listener Design

1. **Single Responsibility Principle**
   ```dart
   // Good - Each listener does one thing
   class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> { }
   class TrackUserAnalyticsListener extends MayrListener<UserRegisteredEvent> { }
   
   // Avoid - Listener doing multiple things
   class UserRegistrationHandler extends MayrListener<UserRegisteredEvent> {
     Future<void> handle(event) {
       sendEmail();
       trackAnalytics();
       updateDatabase();
       notifyAdmins();
     }
   }
   ```

2. **Handle errors appropriately**
   ```dart
   class ResilientListener extends MayrListener<MyEvent> {
     @override
     Future<void> handle(MyEvent event) async {
       try {
         await riskyOperation();
       } catch (e) {
         // Log error but don't rethrow unless critical
         logger.error('Operation failed: $e');
         // Fallback behavior
         await fallbackOperation();
       }
     }
   }
   ```

### Performance

1. **Use isolates for CPU-intensive work**
   ```dart
   class DataProcessingListener extends MayrListener<DataReceivedEvent> {
     @override
     bool get runInIsolate => true;  // Run in separate isolate
     
     @override
     Future<void> handle(DataReceivedEvent event) async {
       // Heavy computation won't block UI
       final result = processLargeDataset(event.data);
     }
   }
   ```

2. **Keep event data serializable for isolates**
   ```dart
   // Good - Simple, serializable data
   class DataEvent extends MayrEvent {
     final List<int> numbers;
     const DataEvent(this.numbers);
   }
   
   // Avoid with isolates - Complex objects may not serialize
   class ComplexEvent extends MayrEvent {
     final Database db;  // Can't be sent to isolate
     final StreamController controller;  // Can't be sent to isolate
     const ComplexEvent(this.db, this.controller);
   }
   ```

### Testing

1. **Clear event bus before each test**
   ```dart
   setUp(() {
     MayrEvents.instance.clear();
   });
   ```

2. **Test listeners in isolation**
   ```dart
   test('listener handles event correctly', () async {
     final listener = MyListener();
     await listener.handle(MyEvent('data'));
     
     expect(listener.processedData, isNotEmpty);
   });
   ```

3. **Test event bus integration**
   ```dart
   test('event fires to all listeners', () async {
     final listener1 = TestListener();
     final listener2 = TestListener();
     
     MayrEvents.on<TestEvent>(listener1);
     MayrEvents.on<TestEvent>(listener2);
     
     await MayrEvents.instance.fire(TestEvent('test'));
     
     expect(listener1.called, true);
     expect(listener2.called, true);
   });
   ```

---

## Complete Example

See [example/lib/main.dart](example/lib/main.dart) for a complete, working Flutter application demonstrating all features.
