## 2.0.0

### 🎉 Major API Simplification & Dart Package Migration

- **BREAKING**: `MayrEvents` now uses a global singleton pattern
- **BREAKING**: `MayrEventSetup` has been **removed** (not just deprecated)
- **BREAKING**: Package converted to pure Dart (removed Flutter dependency)
- **BREAKING**: Static `fire()` method is now on base `MayrEvents` class
- ✅ Simplified pattern: extend `MayrEvents` with only 3 methods
- ✅ Users call `MayrEvents.fire()` directly (not `MyEvents.fire()`)
- ✅ Automatic lazy initialization on first use
- ✅ No singleton boilerplate needed in user classes
- ✅ Repository moved to MayR Labs organization
- ✅ New repository: https://github.com/MayR-Labs/dart_events

### Migration

See [MIGRATION.md](MIGRATION.md) for detailed upgrade instructions.

**Before (v1.x):**
```dart
class MyEvents extends MayrEventSetup { ... }
await MyEvents().init();
await MayrEvents.instance.fire(event);
```

**After (v2.0):**
```dart
class MyEvents extends MayrEvents { ... }
void main() {
  MyEvents(); // Initialize once
}
await MayrEvents.fire(event); // Use base class static method
```

### Updated

- Documentation updated for new pattern
- Example app updated
- All tests updated
- Package now pure Dart (no Flutter dependency)
- Links updated to MayR Labs organization

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
