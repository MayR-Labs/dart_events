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
