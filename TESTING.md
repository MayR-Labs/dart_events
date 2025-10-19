# Testing Mayr Events

This document explains how to test the mayr_events package.

## Prerequisites

- Flutter SDK installed and configured
- Dart SDK (comes with Flutter)

## Running Tests

### Full Test Suite

To run the complete Flutter test suite:

```bash
flutter test
```

### With Coverage

To run tests with coverage report:

```bash
flutter test --coverage
```

### Format Check

```bash
dart format --set-exit-if-changed .
```

### Analysis

```bash
dart analyze --fatal-warnings .
```

### All Checks (Recommended)

Use the provided test script:

```bash
./test.sh
```

## Test Structure

The test suite (`test/mayr_events_test.dart`) includes:

- **Unit tests** for each component:
  - MayrEvent
  - MayrListener
  - MayrEvents (event bus)
  - MayrEventSetup

- **Integration tests** for complete workflows

- **Edge case tests**:
  - Once-only listeners
  - Error handling
  - Multiple listeners
  - Hooks (beforeHandle, onError)

## Simple Standalone Test

For quick verification without Flutter, a simple standalone test is available:

```bash
dart test/simple_test.dart
```

Note: This requires the package dependencies to be resolved, which requires Flutter.

## Writing New Tests

When adding new features, follow these guidelines:

1. **Create test events and listeners** specific to your test case
2. **Reset the event bus** before each test using `MayrEvents.instance.clear()`
3. **Test both success and failure cases**
4. **Use descriptive test names**
5. **Check edge cases**

### Example Test Structure

```dart
group('Feature Name', () {
  setUp(() {
    MayrEvents.instance.clear();
  });

  test('should do something specific', () async {
    // Arrange
    final listener = TestListener();
    MayrEvents.instance.listen<TestEvent>(listener);

    // Act
    await MayrEvents.instance.fire(const TestEvent('data'));

    // Assert
    expect(listener.messages, ['data']);
  });
});
```

## Continuous Integration

The package uses GitHub Actions for CI. See `.github/workflows/ci.yaml` for the complete CI configuration.

The CI pipeline runs:
1. Flutter pub get
2. Flutter test
3. Dart format check
4. Dart analyze

## Test Coverage

We aim for high test coverage (>90%) to ensure reliability. After running tests with coverage:

```bash
# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

## Troubleshooting

### Package Resolution Errors

If you see "Failed to resolve package" errors:

```bash
flutter clean
flutter pub get
```

### Flutter SDK Issues

Ensure Flutter is properly installed:

```bash
flutter doctor
```

### Test Failures

1. Check that you've cleared the event bus before each test
2. Verify async/await usage is correct
3. Ensure test events and listeners are properly isolated
4. Check for timing issues in async tests

## Manual Testing

You can also test the package manually using the example app:

```bash
cd example
flutter pub get
flutter run
```

Interact with the UI and observe console output to verify behavior.
