![License](https://img.shields.io/badge/license-MIT-blue.svg?label=Licence)
![Platform](https://img.shields.io/badge/Platform-Flutter-blue.svg)

![Pub Version](https://img.shields.io/pub/v/mayr_events?style=plastic&label=Version)
![Pub.dev Score](https://img.shields.io/pub/points/mayr_events?label=Score&style=plastic)
![Pub Likes](https://img.shields.io/pub/likes/mayr_events?label=Likes&style=plastic)
![Pub.dev Publisher](https://img.shields.io/pub/publisher/mayr_events?label=Publisher&style=plastic)
![Downloads](https://img.shields.io/pub/dm/mayr_events.svg?label=Downloads&style=plastic)

![Build Status](https://img.shields.io/github/actions/workflow/status/YoungMayor/mayr_flutter_events/ci.yaml?label=Build)
![Issues](https://img.shields.io/github/issues/YoungMayor/mayr_flutter_events.svg?label=Issues)
![Last Commit](https://img.shields.io/github/last-commit/YoungMayor/mayr_flutter_events.svg?label=Latest%20Commit)
![Contributors](https://img.shields.io/github/contributors/YoungMayor/mayr_flutter_events.svg?label=Contributors)


# mayr_events

A lightweight, expressive event and listener system for Flutter and Dart — inspired by Laravel’s event architecture.

Mayr Events helps you decouple logic in your app using an elegant, easy-to-read syntax while supporting async listeners, isolates, middleware hooks, and more.

---

## 🚀 Features

- ✅ Simple and expressive API
- ✅ Async listeners (run in isolate)
- ✅ Middleware-style `beforeHandle` hooks
- ✅ Global `onError` handler
- ✅ Once-only listeners
- ✅ Auto event registration
- ✅ Works seamlessly across Flutter or pure Dart

---

## 🧩 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mayr_events: ^1.0.0
````

Then import:

```dart
import 'package:mayr_events/mayr_events.dart';
```

> 💡 **New to mayr_events?** Check out the [Quick Start Guide](QUICKSTART.md) for a 5-minute tutorial!

---

## ⚙️ Setup

Start by creating an **Event Setup** class that defines your listeners.

```dart
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

Call `init()` in your `main()` (preferably before running your app):

```dart
void main() async {
  await MyAppEvents().init();
  runApp(MyApp());
}
```

---

## 🧠 Defining Events

Events are simple data classes extending `MayrEvent` (we recommend defining all your events on a folder for better organisation):

```dart
class UserRegisteredEvent extends MayrEvent {
  final String userId;

  const UserRegisteredEvent(this.userId);
}
```

---

## ⚡ Creating Listeners

Listeners extend `MayrListener<T>` and define how to handle the event (we recommend defining all your listeners on one folder for better organisation).

```dart
class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  // Setting this to true causes the event to run in an isolate
  bool get runInIsolate => true;

  @override
  /// Setting this to true causes the listener to run only once per lifecycle
  bool get once => true;

  @override
  Future<void> handle(UserRegisteredEvent event) async {
    await EmailService.sendWelcome(event.userId);

    print('Welcome email sent!');
  }
}
```

**Once-only listeners:**

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
MayrEvents.fire(UserRegisteredEvent('U123'));
```

All matching listeners will automatically run (some even in isolates).

---

## 🧩 Advanced Example

```dart
class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;

  const OrderPlacedEvent(this.orderId, this.total);
}

class OrderAnalyticsListener extends MayrListener<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    print('Analytics logged for order ${event.orderId}');
  }
}

void main() async {
  await MyAppEvents().init();

  MayrEvents.fire(OrderPlacedEvent('ORD_908', 1200));
}
```

---

## 🧱 Philosophy

> *"Keep it expressive. Keep it simple. Keep it Mayr."*
> This package is designed for developers who value clarity over complexity, and who want a Laravel-style event flow inside Flutter.

---

## 📢 Additional Information

### 🤝 Contributing
Contributions are highly welcome!
If you have ideas for new extensions, improvements, or fixes, feel free to fork the repository and submit a pull request.

Please make sure to:
- Follow the existing coding style.
- Write tests for new features.
- Update documentation if necessary.

> Let's build something amazing together!

For detailed contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

### 📚 Additional Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute tutorial to get started
- **[API.md](API.md)** - Complete API reference and best practices
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Detailed guidelines for contributors
- **[TESTING.md](TESTING.md)** - Information about running and writing tests
- **[DESIGN.md](DESIGN.md)** - Architecture and design decisions
- **[example/](example/)** - Working Flutter example application

---

### 🐛 Reporting Issues
If you encounter a bug, unexpected behaviour, or have feature requests:
- Open an issue on the repository.
- Provide a clear description and steps to reproduce (if it's a bug).
- Suggest improvements if you have any ideas.

> Your feedback helps make the package better for everyone!

---

### 🧑‍💻 Author

**MayR Labs**

Crafting clean, reliable, and human-centric Flutter and Dart solutions.
🌍 [mayrlabs.com](https://mayrlabs.com)

---

### 📜 Licence
This package is licensed under the MIT License — which means you are free to use it for commercial and non-commercial projects, with proper attribution.

> See the [LICENSE](LICENSE) file for more details.

MIT © 2025 [MayR Labs](https://github.com/mayrlabs)

---

## 🌟 Support

If you find this package helpful, please consider giving it a ⭐️ on GitHub — it motivates and helps the project grow!

You can also support by:
- Sharing the package with your friends, colleagues, and tech communities.
- Using it in your projects and giving feedback.
- Contributing new ideas, features, or improvements.

> Every little bit of support counts! 🚀💙
