### 💡 Core Idea

We’re keeping it simple and expressive:

* `MayrEvent` → defines data
* `MayrListener<T extends MayrEvent>` → handles logic
* `MayrEventBus` (or `MayrEvents`) → fires, manages, and queues
* `MayrEventSetup` → the app-level configuration hub

---

### 🚀 Updated Architecture

#### **1. MayrEventSetup**

This is the entrypoint. It’s where you register listeners, define global behaviours, and initialise the system.

```dart
abstract class MayrEventSetup {
  /// Register all event-listener bindings
  void registerListeners(MayrEvents events);

  /// Run before every listener handle()
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {}

  /// Global error handler for listener failures
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {}

  /// Call this in main()
  Future<void> init() async {
    final events = MayrEvents.instance;
    registerListeners();
    events.beforeHandle = beforeHandle;
    events.onError = onError;
  }
}
```

This gives you a central place to:

* add **middleware-like behaviour** (beforeHandle)
* catch global listener errors (onError)
* ensure clean and consistent setup

---

#### **2. MayrEvent**

```dart
abstract class MayrEvent {
  const MayrEvent();
}
```

Simple and immutable by design — you’d just subclass it.

```dart
class UserRegistered extends MayrEvent {
  final String userId;
  const UserRegistered(this.userId);
}
```

---

#### **3. MayrListener**

```dart
abstract class MayrListener<T extends MayrEvent> {
  /// Whether this listener should only run once
  bool get once => false;

  /// Handle event
  Future<void> handle(T event);

  /// Optional setting to queue the notification or run it instantly
  bool get queued => true;

  /// Optional isolate-friendly version
  bool get runInIsolate => false;
}
```

Example:

```dart
class SendWelcomeEmail extends MayrListener<UserRegistered> {
  @override
  bool get runInIsolate => true;

  @override
  Future<void> handle(UserRegistered event) async {
    await EmailService.sendWelcome(event.userId);
  }
}
```

---

#### **4. MayrEvents (the bus)**

Handles firing, queueing, once-only logic, and async execution.

```dart
class MayrEvents {
  static final MayrEvents instance = MayrEvents._();
  MayrEvents._();

  final Map<Type, List<MayrListener>> _listeners = {};
  Future<void> Function(MayrEvent, MayrListener)? beforeHandle;
  Future<void> Function(MayrEvent, Object, StackTrace)? onError;

  void listen<T extends MayrEvent>(MayrListener<T> listener) {
    _listeners.putIfAbsent(T, () => []).add(listener);
  }

  Future<void> fire<T extends MayrEvent>(T event) async {
    final listeners = _listeners[T] ?? [];
    for (final listener in List.of(listeners)) {
      if (beforeHandle != null) await beforeHandle!(event, listener);
      try {
        if (listener.runInIsolate) {
          await Isolate.run(() => listener.handle(event));
        } else {
          await listener.handle(event);
        }
        if (listener.once) {
          _listeners[T]!.remove(listener);
        }
      } catch (e, s) {
        if (onError != null) await onError!(event, e, s);
      }
    }
  }
}
```

---

### 🧠 Example Usage

```dart
void main() async {
  await MyAppEvents().init();

  // Rest of code...
}

void elsewhere() async {
  MayrEvents.instance.fire(UserRegisteredEvent('U123'));
}

class MyAppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
    MayrEvents.on<OrderPlacedEvent>(OrderAnalyticsListener());
  }

  @override
  Future<void> beforeHandle(event, listener) async {
    print('[Before] ${listener.runtimeType} for ${event.runtimeType}');
  }

  @override
  Future<void> onError(event, error, stack) async {
    print('[Error] ${event.runtimeType}: $error');
  }
}
```

Output:

```
[Before] SendWelcomeEmail for UserRegistered
✅ Email sent in isolate
```
