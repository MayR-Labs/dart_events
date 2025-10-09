# Contributing to Mayr Events

First off, thank you for considering contributing to Mayr Events! 🎉

It's people like you that make Mayr Events such a great tool for the Flutter and Dart community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)

## 📜 Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. Be respectful, considerate, and collaborative.

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots, etc.)
- **Describe the behavior you observed** and what you expected
- **Include your environment details** (Dart/Flutter version, OS, etc.)

**Template:**

```markdown
**Description:**
A clear description of the bug.

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What you expected to happen.

**Actual Behavior:**
What actually happened.

**Environment:**
- Dart version: X.X.X
- Flutter version: X.X.X
- OS: [e.g., macOS 14.0]
- Package version: X.X.X
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **Provide examples** of how it would be used
- **List any potential drawbacks** or alternatives you've considered

### Pull Requests

We actively welcome your pull requests! Here's how to contribute code:

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding guidelines
3. **Add tests** for your changes
4. **Ensure all tests pass**
5. **Format your code** using `dart format`
6. **Analyze your code** using `dart analyze`
7. **Update documentation** if needed
8. **Submit your pull request**

## 🛠️ Development Setup

1. **Clone the repository:**

```bash
git clone https://github.com/YoungMayor/mayr_flutter_events.git
cd mayr_flutter_events
```

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Run tests:**

```bash
flutter test
```

4. **Run the example:**

```bash
cd example
flutter pub get
flutter run
```

## 📝 Coding Guidelines

### Dart Style Guide

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

### Code Formatting

Always format your code before committing:

```bash
dart format .
```

### Code Analysis

Ensure your code has no analysis errors:

```bash
dart analyze --fatal-warnings .
```

### Documentation

- **All public APIs must have dartdoc comments**
- Use `///` for documentation comments
- Include examples in documentation where helpful
- Keep documentation clear, concise, and accurate

**Example:**

```dart
/// Fires an event to all registered listeners.
///
/// All listeners registered for the event type [T] will be executed.
/// Listeners marked with `once = true` will be automatically removed
/// after handling the event.
///
/// ## Example
///
/// ```dart
/// await MayrEvents.fire(UserRegisteredEvent('user123', 'user@example.com'));
/// ```
Future<void> fire<T extends MayrEvent>(T event) async {
  // Implementation
}
```

### Naming Conventions

- **Classes:** PascalCase (e.g., `MayrEvent`, `UserRegisteredEvent`)
- **Variables/Functions:** camelCase (e.g., `fire`, `registerListeners`)
- **Constants:** camelCase (e.g., `maxRetries`)
- **Private members:** Prefix with underscore (e.g., `_listeners`)

## 💬 Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat:** A new feature
- **fix:** A bug fix
- **docs:** Documentation only changes
- **style:** Code style changes (formatting, missing semi-colons, etc.)
- **refactor:** Code change that neither fixes a bug nor adds a feature
- **perf:** Performance improvement
- **test:** Adding or updating tests
- **chore:** Changes to build process or auxiliary tools

### Examples

```
feat(events): add support for priority-based listeners

Add ability to specify listener priority to control execution order.
Listeners with higher priority execute first.

Closes #123
```

```
fix(listener): prevent memory leak in once-only listeners

Once-only listeners were not being properly removed after execution
in certain edge cases, causing memory leaks.

Fixes #456
```

```
docs(readme): add example for error handling

Added comprehensive example showing how to use the onError hook
for proper error handling in listeners.
```

## 🔄 Pull Request Process

1. **Create a feature branch:**

```bash
git checkout -b feat/my-new-feature
```

2. **Make your changes and commit:**

```bash
git add .
git commit -m "feat: add my new feature"
```

3. **Push to your fork:**

```bash
git push origin feat/my-new-feature
```

4. **Open a Pull Request** on GitHub with:
   - Clear title describing the change
   - Detailed description of what changed and why
   - Reference to any related issues
   - Screenshots/GIFs if UI changes are involved

5. **Address review feedback** if any

6. **Once approved**, your PR will be merged!

### Pull Request Checklist

- [ ] Tests pass (`flutter test`)
- [ ] Code is formatted (`dart format .`)
- [ ] Code has no analysis warnings (`dart analyze`)
- [ ] Documentation is updated
- [ ] Example is updated if relevant
- [ ] CHANGELOG.md is updated (for significant changes)
- [ ] Commit messages follow guidelines

## 🧪 Testing Guidelines

### Writing Tests

- **Write tests for all new features**
- **Update tests when changing existing features**
- **Aim for high test coverage**
- **Test edge cases and error conditions**

### Test Structure

```dart
group('Feature Name', () {
  setUp(() {
    // Setup code
  });

  test('should do something specific', () {
    // Arrange
    final event = TestEvent('data');

    // Act
    final result = doSomething(event);

    // Assert
    expect(result, expectedValue);
  });
});
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/mayr_events_test.dart

# Run tests with coverage
flutter test --coverage
```

## 📚 Additional Resources

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Package Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Dart API Documentation Guidelines](https://dart.dev/guides/language/effective-dart/documentation)

## 🙏 Thank You!

Your contributions make Mayr Events better for everyone. We appreciate your time and effort in making this project awesome! 💙

If you have questions, feel free to:
- Open an issue for discussion
- Reach out to the maintainers
- Check existing documentation

Happy coding! 🚀
