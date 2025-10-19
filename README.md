![License](https://img.shields.io/badge/license-MIT-blue.svg?label=Licence)
![Platform](https://img.shields.io/badge/Platform-Dart-blue.svg)

![Pub Version](https://img.shields.io/pub/v/mayr_events?style=plastic&label=Version)
![Pub.dev Score](https://img.shields.io/pub/points/mayr_events?label=Score&style=plastic)
![Pub Likes](https://img.shields.io/pub/likes/mayr_events?label=Likes&style=plastic)

# mayr_events

A lightweight, expressive event and listener system for Dart — inspired by Laravel's event architecture.

Mayr Events helps you decouple logic in your app using an elegant, easy-to-read syntax while supporting async listeners, isolates, middleware hooks, and more.

---

## 🚀 Features

- ✅ Simple functional API - no class extension needed
- ✅ Event-level hooks (beforeHandle, shouldHandle, onError)
- ✅ Global keyed handlers for cross-cutting concerns
- ✅ Async listeners with isolate support
- ✅ Once-only listeners
- ✅ Pure Dart - works everywhere

---

## 🧩 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mayr_events: ^2.0.0
```

Then import:

```dart
import 'package:mayr_events/mayr_events.dart';
```

> 💡 **New to mayr_events?** Check out the [Quick Start Guide](QUICKSTART.md) for a 5-minute tutorial!

---

## ⚙️ Setup

Create a function to register your listeners and handlers:

```dart
void setupEvents() {
  // Register listeners
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());

  // Add global handlers
  MayrEvents.beforeHandle('logger', (event, listener) async {
    print('Handling ${event.runtimeType}');
  });

  MayrEvents.onError('error_logger', (event, error, stack) async {
    print('Error: $error');
  });

  MayrEvents.shouldHandle('validator', (event) {
    // Return false to prevent listener execution
    return true;
  });
}
```

Call this function before firing any events (typically in `main()`):

```dart
void main() {
  setupEvents();
  runApp(MyApp());
}
```

---

## 🧠 Defining Events

Events are simple data classes extending `MayrEvent`:

```dart
class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;

  const UserRegisteredEvent(this.userId, this.email);
}
```

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

  @override
  bool Function(MayrEvent)? get shouldHandle =>
      (event) => (event as UserRegisteredEvent).userId.isNotEmpty;

  @override
  Future<void> Function(MayrEvent, Object, StackTrace)? get onError =>
      (event, error, stack) async {
        print('Registration failed: $error');
      };
}
```

---

## 👂 Defining Listeners

Listeners handle events:

```dart
class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    await EmailService.sendWelcome(event.userId);
    print('Welcome email sent to ${event.email}');
  }
}
```

### Once-Only Listeners

```dart
class TrackAppLaunchListener extends MayrListener<AppLaunchedEvent> {
  @override
  bool get once => true;

  @override
  Future<void> handle(AppLaunchedEvent event) async {
    print('This listener runs only once.');
  }
}
```

---

## 🚀 Firing Events

Anywhere in your app:

```dart
await MayrEvents.fire(UserRegisteredEvent('U123', 'user@example.com'));
```

---

## 🔧 Advanced Features

### Global Handlers with Keys

Register multiple handlers using unique keys:

```dart
// Add handlers
MayrEvents.beforeHandle('logger', loggerCallback);
MayrEvents.beforeHandle('metrics', metricsCallback);
MayrEvents.onError('sentry', sentryCallback);
MayrEvents.shouldHandle('rate_limiter', rateLimitCallback);

// Remove specific handlers
MayrEvents.removeBeforeHandler('logger');
MayrEvents.removeErrorHandler('sentry');
MayrEvents.removeShouldHandle('rate_limiter');
```

### Listener Management

```dart
// Remove specific listener
final listener = SendWelcomeEmailListener();
MayrEvents.on<UserRegisteredEvent>(listener);
MayrEvents.remove<UserRegisteredEvent>(listener);

// Remove all listeners for an event
MayrEvents.removeAll<UserRegisteredEvent>();

// Clear everything
MayrEvents.clear();

// Check listeners
bool hasListeners = MayrEvents.hasListeners<UserRegisteredEvent>();
int count = MayrEvents.listenerCount<UserRegisteredEvent>();
```

### Run Listeners in Isolates

For CPU-intensive operations:

```dart
class HeavyProcessingListener extends MayrListener<DataEvent> {
  @override
  bool get runInIsolate => true;

  @override
  Future<void> handle(DataEvent event) async {
    // CPU-intensive work runs in separate isolate
  }
}
```

---

## 📚 Complete Example

```dart
import 'package:mayr_events/mayr_events.dart';

// Define event
class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;
  const OrderPlacedEvent(this.orderId, this.total);
}

// Define listener
class ProcessOrderListener extends MayrListener<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    print('Processing order ${event.orderId}');
  }
}

void setupEvents() {
  MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());
  
  MayrEvents.beforeHandle('logger', (event, listener) async {
    print('[${DateTime.now()}] Event fired');
  });
}

void main() async {
  setupEvents();
  await MayrEvents.fire(OrderPlacedEvent('ORD_123', 99.99));
}
```

---

## 🔄 Migration from v1.x

See [MIGRATION.md](MIGRATION.md) for detailed upgrade instructions.

**Key Changes in v2.0:**
- No class extension required - use functional API
- Event-level hooks available
- Keyed handler system for better control
- Pure Dart package (no Flutter dependency)

---

## 📖 Documentation

- [Quick Start Guide](QUICKSTART.md)
- [Migration Guide](MIGRATION.md)
- [Changelog](CHANGELOG.md)
- [API Documentation](https://pub.dev/documentation/mayr_events/latest/)

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🔗 Links

- **Repository**: https://github.com/MayR-Labs/dart_events
- **Homepage**: https://mayrlabs.com
- **Issues**: https://github.com/MayR-Labs/dart_events/issues
