import 'dart:async';
import 'dart:isolate';

import 'mayr_event.dart';
import 'mayr_listener.dart';

/// Global event bus for the Mayr Events system.
///
/// This class provides static methods for registering listeners and firing events.
/// Users don't need to extend any class, just use the static methods directly.
///
/// ## Usage
///
/// ```dart
/// void setupEvents() {
///   MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
///   MayrEvents.beforeHandle('logger', (event, listener) async {
///     print('Handling ${event.runtimeType}');
///   });
/// }
///
/// void main() {
///   setupEvents();
///   runApp(MyApp());
/// }
///
/// // Fire events anywhere
/// await MayrEvents.fire(UserRegisteredEvent('user123', 'user@example.com'));
/// ```
class MayrEvents {
  MayrEvents._();

  /// Singleton instance
  static final MayrEvents _instance = MayrEvents._();

  /// Map of event types to their registered listeners.
  final Map<Type, List<MayrListener>> _listeners = {};

  /// Map of keyed callbacks to run before each listener handles an event.
  final Map<String, Future<void> Function(MayrEvent, MayrListener)>
  _beforeHandlers = {};

  /// Map of keyed callbacks for error handling.
  final Map<String, Future<void> Function(MayrEvent, Object, StackTrace)>
  _errorHandlers = {};

  /// Map of keyed callbacks that determine if a listener should handle an event.
  final Map<String, bool Function(MayrEvent)> _shouldHandlers = {};

  /// Registers a listener for a specific event type.
  ///
  /// ```dart
  /// MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  /// ```
  static void on<T extends MayrEvent>(MayrListener<T> listener) {
    _instance._listeners.putIfAbsent(T, () => []).add(listener);
  }

  /// Adds a beforeHandle callback with a key.
  ///
  /// The callback will be executed before each listener handles an event.
  ///
  /// ```dart
  /// MayrEvents.beforeHandle('logger', (event, listener) async {
  ///   print('Handling ${event.runtimeType} with ${listener.runtimeType}');
  /// });
  /// ```
  static void beforeHandle(
    String key,
    Future<void> Function(MayrEvent event, MayrListener listener) callback,
  ) {
    _instance._beforeHandlers[key] = callback;
  }

  /// Adds an error handler callback with a key.
  ///
  /// The callback will be executed when a listener throws an error.
  ///
  /// ```dart
  /// MayrEvents.onError('logger', (event, error, stack) async {
  ///   print('Error: $error');
  /// });
  /// ```
  static void onError(
    String key,
    Future<void> Function(MayrEvent event, Object error, StackTrace stack)
    callback,
  ) {
    _instance._errorHandlers[key] = callback;
  }

  /// Adds a shouldHandle callback with a key.
  ///
  /// The callback receives an event and returns whether listeners should handle it.
  /// If any shouldHandle returns false, the listener will not run.
  ///
  /// ```dart
  /// MayrEvents.shouldHandle('validator', (event) {
  ///   return event is UserRegisteredEvent && event.userId.isNotEmpty;
  /// });
  /// ```
  static void shouldHandle(
    String key,
    bool Function(MayrEvent event) callback,
  ) {
    _instance._shouldHandlers[key] = callback;
  }

  /// Removes a beforeHandle callback by key.
  static void removeBeforeHandler(String key) {
    _instance._beforeHandlers.remove(key);
  }

  /// Removes an error handler callback by key.
  static void removeErrorHandler(String key) {
    _instance._errorHandlers.remove(key);
  }

  /// Removes a shouldHandle callback by key.
  static void removeShouldHandle(String key) {
    _instance._shouldHandlers.remove(key);
  }

  /// Fires an event to all registered listeners.
  ///
  /// ```dart
  /// await MayrEvents.fire(UserRegisteredEvent('user123', 'user@example.com'));
  /// ```
  static Future<void> fire<T extends MayrEvent>(T event) async {
    final listeners = _instance._listeners[T] ?? [];

    for (final listener in List<MayrListener>.of(listeners)) {
      // Check event-level shouldHandle if it exists
      if (event.shouldHandle != null && !event.shouldHandle!(event)) {
        continue;
      }

      // Check global shouldHandle callbacks
      bool shouldRun = true;
      for (final callback in _instance._shouldHandlers.values) {
        if (!callback(event)) {
          shouldRun = false;
          break;
        }
      }

      if (!shouldRun) {
        continue;
      }

      // Run event-level beforeHandle if it exists
      if (event.beforeHandle != null) {
        await event.beforeHandle!(event, listener);
      }

      // Run global beforeHandle callbacks
      for (final callback in _instance._beforeHandlers.values) {
        await callback(event, listener);
      }

      try {
        // Execute listener in isolate or main thread
        if (listener.runInIsolate) {
          await Isolate.run(() => listener.handle(event));
        } else {
          await listener.handle(event);
        }

        // Remove once-only listeners after successful execution
        if (listener.once) {
          _instance._listeners[T]?.remove(listener);
        }
      } catch (e, s) {
        // Run event-level error handler if it exists
        if (event.onError != null) {
          await event.onError!(event, e, s);
        }

        // Run global error handlers
        for (final callback in _instance._errorHandlers.values) {
          await callback(event, e, s);
        }
      }
    }
  }

  /// Removes a specific listener for an event type.
  static void remove<T extends MayrEvent>(MayrListener<T> listener) {
    _instance._listeners[T]?.remove(listener);
  }

  /// Removes all listeners for a specific event type.
  static void removeAll<T extends MayrEvent>() {
    _instance._listeners.remove(T);
  }

  /// Clears all registered listeners and handlers.
  static void clear() {
    _instance._listeners.clear();
    _instance._beforeHandlers.clear();
    _instance._errorHandlers.clear();
    _instance._shouldHandlers.clear();
  }

  /// Returns the number of listeners registered for an event type.
  static int listenerCount<T extends MayrEvent>() {
    return _instance._listeners[T]?.length ?? 0;
  }

  /// Returns whether any listeners are registered for an event type.
  static bool hasListeners<T extends MayrEvent>() {
    return (_instance._listeners[T]?.isNotEmpty ?? false);
  }
}
