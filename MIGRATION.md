# Migration Guide: v1.x to v2.0

This guide helps you migrate to the new functional API in v2.0.

## What Changed?

The v2.0 release completely redesigns the API to use a functional approach without requiring class extension.

**Old Pattern (v1.x):**
```dart
// Had to extend a class
class MyEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    MayrEvents.on<UserEvent>(UserListener());
  }
}

// Had to call init
void main() async {
  await MyEvents().init();
  runApp(MyApp());
}

// Fire events
await MayrEvents.instance.fire(UserEvent());
```

**New Pattern (v2.0):**
```dart
// Just a function - no class extension needed!
void setupEvents() {
  MayrEvents.on<UserEvent>(UserListener());
  
  // Can add keyed handlers
  MayrEvents.beforeHandle('logger', (event, listener) async {
    print('Handling ${event.runtimeType}');
  });
}

// Call setup function
void main() {
  setupEvents();
  runApp(MyApp());
}

// Fire events - simpler!
await MayrEvents.fire(UserEvent());
```

## Migration Steps

### Step 1: Replace Class with Function

**Before:**
```dart
class AppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  }
  
  @override
  Future<void> beforeHandle(event, listener) async {
    print('Handling event');
  }
}
```

**After:**
```dart
void setupEvents() {
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  
  // Convert hooks to keyed handlers
  MayrEvents.beforeHandle('app_logger', (event, listener) async {
    print('Handling event');
  });
}
```

### Step 2: Update Initialization

**Before:**
```dart
void main() async {
  await AppEvents().init();
  runApp(MyApp());
}
```

**After:**
```dart
void main() {
  setupEvents();
  runApp(MyApp());
}
```

### Step 3: Update Event Firing

**Before:**
```dart
await MayrEvents.instance.fire(UserRegisteredEvent(userId, email));
```

**After:**
```dart
await MayrEvents.fire(UserRegisteredEvent(userId, email));
```

### Step 4: Convert Hooks to Keyed Handlers

**Before (class-level hooks):**
```dart
class AppEvents extends MayrEventSetup {
  @override
  Future<void> beforeHandle(event, listener) async {
    // Hook logic
  }
  
  @override
  Future<void> onError(event, error, stack) async {
    // Error handling
  }
}
```

**After (keyed handlers):**
```dart
void setupEvents() {
  MayrEvents.beforeHandle('logger', (event, listener) async {
    // Hook logic
  });
  
  MayrEvents.onError('error_handler', (event, error, stack) async {
    // Error handling
  });
  
  // NEW: shouldHandle validator
  MayrEvents.shouldHandle('validator', (event) {
    // Return false to prevent execution
    return true;
  });
}
```

## New Features in v2.0

### 1. Event-Level Hooks

Events can now have their own hooks:

```dart
class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;
  
  const UserRegisteredEvent(this.userId, this.email);
  
  @override
  Future<void> Function(MayrEvent, MayrListener)? get beforeHandle =>
      (event, listener) async {
        print('Event-specific hook');
      };
  
  @override
  bool Function(MayrEvent)? get shouldHandle =>
      (event) => (event as UserRegisteredEvent).userId.isNotEmpty;
  
  @override
  Future<void> Function(MayrEvent, Object, StackTrace)? get onError =>
      (event, error, stack) async {
        print('Event-specific error handler');
      };
}
```

### 2. Keyed Handler System

Manage handlers with unique keys:

```dart
// Add handlers
MayrEvents.beforeHandle('logger', logCallback);
MayrEvents.beforeHandle('metrics', metricsCallback);
MayrEvents.onError('sentry', sentryCallback);

// Remove specific handlers
MayrEvents.removeBeforeHandler('logger');
MayrEvents.removeErrorHandler('sentry');
```

### 3. ShouldHandle Callbacks

New validation system:

```dart
MayrEvents.shouldHandle('rate_limiter', (event) {
  // Return false to skip listener execution
  return !isRateLimited();
});
```

### 4. Handler Removal

Clean up specific handlers:

```dart
MayrEvents.removeBeforeHandler('key');
MayrEvents.removeErrorHandler('key');
MayrEvents.removeShouldHandle('key');
```

## Breaking Changes

1. **MayrEventSetup removed** - No longer exists
2. **No class extension** - Use functional approach
3. **MayrEvents.instance removed** - Use static methods directly
4. **Init method removed** - Just call setup function
5. **Pure Dart** - No Flutter dependency

## Key Benefits

1. **Simpler** - No class boilerplate
2. **More flexible** - Event-level hooks
3. **Better control** - Keyed handler system
4. **Cleaner** - Functional approach
5. **Universal** - Pure Dart works everywhere

## Need Help?

If you encounter issues during migration:
1. Check the [README](README.md) for the latest examples
2. Review the [Quick Start Guide](QUICKSTART.md)
3. Look at the updated [example app](example/)
4. Open an issue on [GitHub](https://github.com/MayR-Labs/dart_events/issues)
