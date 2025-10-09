# Project Structure

Overview of the mayr_events package structure and organization.

## Directory Layout

```
mayr_flutter_events/
├── lib/                        # Source code
│   ├── src/                    # Implementation files
│   │   ├── mayr_event.dart           # Base event class
│   │   ├── mayr_listener.dart        # Base listener class
│   │   ├── mayr_events.dart          # Event bus implementation
│   │   └── mayr_event_setup.dart     # Setup/configuration class
│   └── mayr_flutter_events.dart      # Main export file
│
├── test/                       # Tests
│   ├── mayr_flutter_events_test.dart # Complete test suite (350+ lines)
│   └── simple_test.dart              # Standalone verification test
│
├── example/                    # Example Flutter app
│   ├── lib/
│   │   └── main.dart                 # Interactive demo app
│   ├── pubspec.yaml
│   └── README.md                     # Example documentation
│
├── docs/                       # Documentation
│   ├── API.md                        # API reference (~450 lines)
│   ├── QUICKSTART.md                 # 5-minute tutorial
│   ├── TESTING.md                    # Testing guide
│   ├── CONTRIBUTING.md               # Contribution guidelines (~270 lines)
│   └── DESIGN.md                     # Architecture and design
│
├── .github/
│   └── workflows/
│       └── ci.yaml                   # GitHub Actions CI
│
├── pubspec.yaml                # Package configuration
├── analysis_options.yaml       # Dart analyzer config
├── CHANGELOG.md                # Version history
├── LICENSE                     # MIT License
├── README.md                   # Main documentation
└── test.sh                     # Test convenience script
```

## Source Files

### lib/mayr_flutter_events.dart
Main entry point that exports all public APIs. This is what users import.

```dart
library mayr_flutter_events;

export 'src/mayr_event.dart';
export 'src/mayr_listener.dart';
export 'src/mayr_events.dart';
export 'src/mayr_event_setup.dart';
```

### lib/src/mayr_event.dart
Defines the base `MayrEvent` class. All events must extend this class.

**Key points:**
- Abstract base class
- Designed for immutability (const constructor)
- Simple by design (no built-in functionality)

### lib/src/mayr_listener.dart
Defines the base `MayrListener<T>` class. All listeners must extend this class.

**Key points:**
- Generic type parameter for event type
- Properties: `once`, `queued`, `runInIsolate`
- Abstract `handle()` method

### lib/src/mayr_events.dart
The event bus implementation. Manages all listeners and fires events.

**Key points:**
- Singleton pattern (`instance` static property)
- Type-safe listener registration
- Async event firing
- Error handling and hooks support
- Utility methods (remove, clear, count, etc.)

### lib/src/mayr_event_setup.dart
Base class for application-level event configuration.

**Key points:**
- Abstract class to be extended by user
- `registerListeners()` - Where user registers all listeners
- `beforeHandle()` and `onError()` hooks
- `init()` - Initializes the event system

## Test Files

### test/mayr_flutter_events_test.dart
Comprehensive test suite using Flutter's test framework.

**Coverage:**
- Unit tests for each component
- Integration tests
- Edge cases (once-only, errors, etc.)
- Hooks testing
- ~350 lines of tests

### test/simple_test.dart
Simplified standalone test for quick verification.

**Purpose:**
- Can run without full Flutter setup
- Quick smoke tests
- Development verification

## Example App

### example/lib/main.dart
Complete working Flutter application demonstrating all features.

**Demonstrates:**
- Event and listener definition
- MayrEventSetup usage
- Multiple events and listeners
- Once-only listeners
- beforeHandle and onError hooks
- UI integration

## Documentation Files

### API.md
Complete API reference with examples and best practices.

**Contains:**
- Full API documentation for all classes
- Method signatures and parameters
- Usage examples
- Best practices
- Common patterns

### QUICKSTART.md
5-minute tutorial for new users.

**Covers:**
- Installation
- Basic setup
- First event and listener
- Common patterns
- Next steps

### TESTING.md
Testing guide for contributors and users.

**Includes:**
- How to run tests
- Test structure
- Writing new tests
- CI information
- Troubleshooting

### CONTRIBUTING.md
Comprehensive contribution guidelines.

**Covers:**
- Code of conduct
- How to contribute
- Development setup
- Coding guidelines
- Commit message format
- PR process

### DESIGN.md
Architecture and design decisions.

**Contains:**
- Core concepts
- Architecture overview
- Design rationale
- Example usage

## Configuration Files

### pubspec.yaml
Package metadata and dependencies.

**Key sections:**
- Package name: `mayr_events`
- Dependencies: Flutter SDK
- Dev dependencies: flutter_test, flutter_lints
- Metadata: description, homepage, repository, etc.

### analysis_options.yaml
Dart analyzer configuration.

**Settings:**
- Includes `flutter_lints` package
- Enforces Flutter best practices

### .github/workflows/ci.yaml
GitHub Actions CI configuration.

**Steps:**
1. Checkout code
2. Setup Flutter
3. Install dependencies
4. Run tests
5. Format check
6. Analyze code

## File Naming Conventions

- **Source files:** snake_case (e.g., `mayr_event.dart`)
- **Test files:** Suffix with `_test.dart`
- **Documentation:** UPPERCASE.md for important docs, PascalCase.md for guides

## Code Organization Principles

### 1. Separation of Concerns
- Core classes in separate files
- Tests mirror source structure
- Examples separate from library

### 2. Progressive Enhancement
- Core functionality is simple
- Advanced features are opt-in
- Documentation progressive (README → QUICKSTART → API)

### 3. Developer Experience
- Clear entry points
- Comprehensive examples
- Multiple documentation levels
- Easy to test

### 4. Maintainability
- Small, focused files
- Clear dependencies
- Comprehensive tests
- Well-documented

## Adding New Features

When adding features to mayr_events:

1. **Add implementation** in `lib/src/`
2. **Export from** `lib/mayr_flutter_events.dart`
3. **Add tests** in `test/mayr_flutter_events_test.dart`
4. **Document in:**
   - Dartdoc comments (in code)
   - API.md (API reference)
   - QUICKSTART.md (if user-facing)
   - README.md (if major feature)
5. **Update example** if applicable
6. **Update CHANGELOG.md**

## Build Artifacts

The following directories are excluded from version control:

- `.dart_tool/` - Pub/Dart tooling cache
- `build/` - Build outputs
- `coverage/` - Test coverage reports
- `.flutter-plugins-dependencies` - Flutter plugin cache

## Development Workflow

1. **Clone repository**
2. **Run `flutter pub get`**
3. **Make changes**
4. **Run `./test.sh`** to verify
5. **Commit changes**
6. **Push to fork**
7. **Create pull request**

## Testing Strategy

- **Unit tests** for individual components
- **Integration tests** for workflows
- **Example app** for manual testing
- **CI** for automated testing

## Documentation Strategy

- **Inline docs** (dartdoc) for API
- **README** for overview and quick examples
- **QUICKSTART** for tutorials
- **API.md** for complete reference
- **Other .md files** for specific topics

---

For more information, see:
- [Contributing Guide](CONTRIBUTING.md)
- [Testing Guide](TESTING.md)
- [API Documentation](API.md)
