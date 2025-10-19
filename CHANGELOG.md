## 2.0.0 (Unreleased)

### 🎉 Major API Simplification

- **BREAKING**: `MayrEvents` is now an abstract base class (was singleton)
- **BREAKING**: Removed `MayrEvents.instance` - users now extend `MayrEvents`
- **BREAKING**: `MayrEventSetup` is deprecated
- ✅ New simplified pattern: users extend `MayrEvents` directly
- ✅ Automatic lazy initialization on first use
- ✅ Static `fire()` method pattern for cleaner syntax
- ✅ No manual `init()` call required
- ✅ Each app has its own events class (better type safety)

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
// No init needed!
await MyEvents.fire(event);
```

### Updated

- Documentation updated for new pattern
- Example app updated
- All tests updated
- README, QUICKSTART, and other guides updated

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
