## 1.1.0

- ✨ **API Enhancement**: All public methods on `MayrEvents` are now static
  - Static methods: `fire()`, `listen()`, `on()`, `remove()`, `removeAll()`, `clear()`, `listenerCount()`, `hasListeners()`
  - Cleaner API: Use `MayrEvents.fire(event)` instead of `MayrEvents.instance.fire(event)`
  - Internal refactoring: Static methods delegate to private instance methods
  - Backward compatible: `MayrEvents.instance` still accessible for advanced use cases
- 🔄 **Package Type**: Converted to pure Dart package
  - Removed Flutter dependencies (`flutter`, `flutter_test`, `flutter_lints`)
  - Now uses standard Dart packages (`test`, `lints`)
  - Works seamlessly with both pure Dart and Flutter projects
- 🏢 **Organization**: Migrated to MayR Labs
  - New repository: https://github.com/MayR-Labs/dart_events
  - Organization: https://github.com/MayR-Labs
  - Website: https://mayrlabs.com
- 📝 **Documentation**: Updated all examples and documentation to use static API
  - README, API.md, QUICKSTART.md, and all other docs aligned with new API
  - Updated test files to use standard `test` package
  - Updated build/test scripts for pure Dart

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
