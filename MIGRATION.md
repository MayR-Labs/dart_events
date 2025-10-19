# Migration Guide: v1.x to v2.0

This guide helps you migrate from the old `MayrEventSetup` pattern to the new simplified `MayrEvents` pattern.

## What Changed?

The new pattern eliminates boilerplate and uses a global singleton:

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
// 1. Create events class (simpler - no singleton boilerplate!)
class MyEvents extends MayrEvents {
  @override
  void registerListeners() {
    on<UserEvent>(UserListener());
  }
}

// 2. Initialize once in main()
void main() async {
  MyEvents(); // That's it!
  runApp(MyApp());
}

// 3. Fire events - uses base class static method
await MayrEvents.fire(UserEvent());
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
  @override
  void registerListeners() {
    on<UserRegisteredEvent>(SendWelcomeEmailListener());  // No MayrEvents. prefix
  }
}
```

### Step 2: Update main() to Create Instance

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
  AppEvents(); // Just create the instance
  runApp(MyApp());
}
```

### Step 3: Update Event Firing

**Before:**
```dart
await MayrEvents.instance.fire(UserRegisteredEvent(userId, email));
// OR
await AppEvents.fire(UserRegisteredEvent(userId, email)); // if you had static method
```

**After:**
```dart
await MayrEvents.fire(UserRegisteredEvent(userId, email));
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

### Step 5: Remove Singleton Boilerplate

If you had this in your events class, remove it:

```dart
// DELETE THESE LINES:
static final AppEvents instance = AppEvents._();
AppEvents._();

static Future<void> fire<T extends MayrEvent>(T event) async {
  await instance._fire(event);
}
```

Your class should only have:
- `registerListeners()` method
- `beforeHandle()` method (optional)
- `onError()` method (optional)

## Key Benefits

1. **Less Boilerplate**: No singleton pattern or static fire method needed
2. **Simpler API**: `MayrEvents.fire()` works everywhere
3. **Global Singleton**: One instance serves the entire app
4. **Clearer Pattern**: Just extend, override methods, and fire

## Important Notes

- **MayrEventSetup is deleted** in v2.0 (not just deprecated)
- All event firing now uses `MayrEvents.fire()` static method
- The system uses a global singleton internally
- Now a pure Dart package (no Flutter dependency)

## Need Help?

If you encounter issues during migration, please:
1. Check the [README](README.md) for the latest examples
2. Review the [Quick Start Guide](QUICKSTART.md)
3. Look at the updated [example app](example/)
4. Open an issue on GitHub if you need assistance
