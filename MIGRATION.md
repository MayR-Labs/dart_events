# Migration Guide: v1.x to v2.0

This guide helps you migrate from the old `MayrEventSetup` pattern to the new simplified `MayrEvents` pattern.

## What Changed?

The new pattern eliminates boilerplate and simplifies the API:

**Old Pattern (v1.x):**
```dart
// 1. Create setup class
class MyEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    MayrEvents.on<UserEvent>(UserListener());
  }
}

// 2. Initialize in main()
void main() async {
  await MyEvents().init();
  runApp(MyApp());
}

// 3. Fire events
await MayrEvents.instance.fire(UserEvent());
```

**New Pattern (v2.0):**
```dart
// 1. Create events class
class MyEvents extends MayrEvents {
  static final MyEvents instance = MyEvents._();
  MyEvents._();

  @override
  void registerListeners() {
    on<UserEvent>(UserListener());
  }

  static Future<void> fire<T extends MayrEvent>(T event) async {
    await instance._fire(event);
  }
}

// 2. No init() needed!
void main() async {
  runApp(MyApp());
}

// 3. Fire events - simpler!
await MyEvents.fire(UserEvent());
```

## Migration Steps

### Step 1: Update Your Events Class

**Before:**
```dart
class AppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  }
}
```

**After:**
```dart
class AppEvents extends MayrEvents {
  static final AppEvents instance = AppEvents._();
  AppEvents._();

  @override
  void registerListeners() {
    on<UserRegisteredEvent>(SendWelcomeEmailListener());  // Changed from MayrEvents.on to just on
  }

  // Add static fire method
  static Future<void> fire<T extends MayrEvent>(T event) async {
    await instance._fire(event);
  }

  // Optional: Add other static convenience methods if needed
  static void clear() => instance.clear();
}
```

### Step 2: Remove init() Call

**Before:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEvents().init();
  runApp(MyApp());
}
```

**After:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No init() call needed - auto-initializes on first use!
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
await AppEvents.fire(UserRegisteredEvent(userId, email));
```

### Step 4: Update Listener Registration (in registerListeners)

**Before:**
```dart
@override
void registerListeners() {
  MayrEvents.on<UserEvent>(UserListener());
}
```

**After:**
```dart
@override
void registerListeners() {
  on<UserEvent>(UserListener());  // Just 'on', not 'MayrEvents.on'
}
```

## Key Benefits

1. **No Manual Initialization**: The system auto-initializes on first use
2. **Simpler API**: `MyEvents.fire()` instead of `MayrEvents.instance.fire()`
3. **Type Safety**: Each app can have its own events class
4. **Less Boilerplate**: No need to call `init()` in main
5. **Clearer Intent**: The events class name appears at every fire site

## Deprecation Notice

`MayrEventSetup` is now deprecated and will be removed in a future version. Please migrate to the new pattern as soon as possible.

## Need Help?

If you encounter issues during migration, please:
1. Check the [README](README.md) for the latest examples
2. Review the [Quick Start Guide](QUICKSTART.md)
3. Look at the updated [example app](example/)
4. Open an issue on GitHub if you need assistance
