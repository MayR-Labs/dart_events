## 2.1.0 (Unreleased)

### 🐛 Bug Fixes

- **FIXED**: Event dispatching now uses `event.runtimeType` instead of generic type `T`
  - Fixes issue where events returned from methods with `MayrEvent` return type weren't dispatched correctly
  - Listeners now properly receive events regardless of the variable's static type

### 🎉 Debug Mode

- ✅ **NEW**: `MayrEvents.debugMode(bool)` - Enable/disable debug output
- ✅ **NEW**: `MayrEvents.debugPrint(String)` - Print debug messages with `[MayrEvents] - ` prefix
- ✅ Debug mode defaults to `true` when assertions are enabled (debug builds)
- ✅ Debug mode defaults to `false` in release builds
- ✅ Debug logging for key actions: `fire`, `on`, `remove`, `removeAll`, `clear`

### Usage

**Debug Mode:**
```dart
// Enable debug output
MayrEvents.debugMode(true);

// Fire events with debug logging
await MayrEvents.fire(UserEvent());
// Output: [MayrEvents] - Firing event UserEvent to 2 listener(s)

// Custom debug messages
MayrEvents.debugPrint('Processing completed');
// Output: [MayrEvents] - Processing completed

// Disable debug output (e.g., in production)
MayrEvents.debugMode(false);
```

**Runtime Type Fix:**
```dart
// This now works correctly!
MayrEvent getEvent(String key) {
  return UserRegisteredEvent('user123', 'user@example.com');
}

final event = getEvent('user_registered'); // Type: MayrEvent
await MayrEvents.fire(event); // Correctly dispatches to UserRegisteredEvent listeners
```

### 🎉 Queued Listeners

- ✅ **NEW**: Queue system for background job processing
- ✅ **NEW**: `MayrEvents.setupQueue()` for configuring queues
- ✅ **NEW**: Multiple named queues with fallback support
- ✅ **NEW**: Automatic retry mechanism (configurable, max 30)
- ✅ **NEW**: Configurable timeout per listener
- ✅ **NEW**: Queue worker lifecycle management (auto-cleanup)
- ✅ **NEW**: Mix queued and non-queued listeners
- ✅ Comprehensive test coverage for queue functionality
- ✅ Example demonstrating queue features

### Listener Properties Added

- `bool get queued` - Enable background queue processing
- `String? get queue` - Specify target queue name
- `Duration get timeout` - Job timeout duration (default: 60s)
- `int get retries` - Retry count on failure (default: 3, max: 30)

### Usage

```dart
void setupEvents() {
  // Setup queues
  MayrEvents.setupQueue(
    fallbackQueue: 'default',
    queues: ['emails', 'notifications'],
    defaultTimeout: Duration(seconds: 60),
  );
  
  MayrEvents.on<OrderEvent>(ProcessOrderListener());
}

class ProcessOrderListener extends MayrListener<OrderEvent> {
  @override
  bool get queued => true;
  
  @override
  String get queue => 'orders';
  
  @override
  int get retries => 5;
  
  @override
  Future<void> handle(OrderEvent event) async {
    // Process in background with automatic retry
  }
}
```

---

## 2.0.0

### 🎉 Complete API Redesign - Functional Approach

- **BREAKING**: Removed class extension pattern - now uses functional API
- **BREAKING**: `MayrEventSetup` completely removed
- **BREAKING**: No more `MayrEvents.instance` - use static methods directly
- **BREAKING**: Pure Dart package (Flutter removed from tests/examples)
- ✅ **NEW**: Event-level hooks (`beforeHandle`, `shouldHandle`, `onError`)
- ✅ **NEW**: Keyed handler system for better management
- ✅ **NEW**: `shouldHandle` callbacks for validation
- ✅ **NEW**: Handler removal methods (`removeBeforeHandler`, etc.)
- ✅ Simplified setup with function-based pattern
- ✅ No class extension or boilerplate needed
- ✅ Pure Dart - works in any Dart project

### New API Pattern

**Setup:**
```dart
void setupEvents() {
  MayrEvents.on<UserEvent>(UserListener());
  MayrEvents.beforeHandle('logger', (event, listener) async { });
  MayrEvents.shouldHandle('validator', (event) => true);
}
```

**Usage:**
```dart
void main() {
  setupEvents();
}

await MayrEvents.fire(UserEvent());
```

### Updated

- Complete rewrite of `MayrEvents` class
- `MayrEvent` base class now supports optional hooks
- Example converted to pure Dart console app
- All tests updated to use `package:test`
- Documentation completely rewritten
- Repository: https://github.com/MayR-Labs/dart_events

---

## 1.0.0

- 🎉 First stable release
- ✅ Complete event system implementation
  - `MayrEvent` - Base class for events
  - `MayrListener` - Base class for event listeners
  - `MayrEvents` - Singleton event bus for firing and managing events
  - `MayrEventSetup` - Application-level configuration
- ✅ Production-ready features
  - Async event handling
  - Multiple listeners per event
  - Once-only listeners
  - Isolate support for CPU-intensive listeners
  - Global hooks (beforeHandle, onError)
  - Type-safe event/listener binding
  - Comprehensive listener management API
- ✅ Comprehensive test suite (672 lines, 12+ test scenarios)
- ✅ Extensive documentation
  - Comprehensive dartdoc comments on all public APIs
  - README with usage examples and quick start
  - QUICKSTART.md - 5-minute tutorial
  - API.md with complete API reference (450+ lines)
  - TESTING.md with testing guidelines
  - CONTRIBUTING.md with contribution guidelines (270+ lines)
  - DESIGN.md with architecture details
  - PROJECT_STRUCTURE.md - Code organization guide
  - CHECKLIST.md - Production readiness verification
- ✅ Working example Flutter application (314 lines)
- ✅ MIT License

## 0.0.1

- Initial placeholder release
