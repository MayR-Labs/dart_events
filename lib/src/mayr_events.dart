import 'dart:async';
import 'dart:isolate';

import 'mayr_event.dart';
import 'mayr_listener.dart';

/// The central event bus for the Mayr Events system.
///
/// This singleton class manages all event listeners and handles
/// firing events to registered listeners.
///
/// ## Usage
///
/// ```dart
/// // Register a listener
/// MayrEvents.instance.listen<UserRegisteredEvent>(
///   SendWelcomeEmailListener(),
/// );
///
/// // Or use the shorter syntax
/// MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
///
/// // Fire an event
/// await MayrEvents.fire(UserRegisteredEvent('user123', 'user@example.com'));
/// ```
class MayrEvents {
  MayrEvents._();

  /// The singleton instance of [MayrEvents].
  static final MayrEvents instance = MayrEvents._();

  /// Map of event types to their registered listeners.
  final Map<Type, List<MayrListener>> _listeners = {};

  /// Callback to run before each listener handles an event.
  ///
  /// This is useful for logging, debugging, or implementing middleware-like behavior.
  Future<void> Function(MayrEvent event, MayrListener listener)? beforeHandle;

  /// Global error handler for listener failures.
  ///
  /// This is called when a listener throws an exception.
  /// If not set, errors will be silently ignored.
  Future<void> Function(MayrEvent event, Object error, StackTrace stack)?
      onError;

  /// Registers a listener for a specific event type.
  ///
  /// The listener will be called whenever an event of type [T] is fired.
  ///
  /// ```dart
  /// MayrEvents.instance.listen<UserRegisteredEvent>(
  ///   SendWelcomeEmailListener(),
  /// );
  /// ```
  void listen<T extends MayrEvent>(MayrListener<T> listener) {
    _listeners.putIfAbsent(T, () => []).add(listener);
  }

  /// Shorthand for [instance.listen].
  ///
  /// ```dart
  /// MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  /// ```
  static void on<T extends MayrEvent>(MayrListener<T> listener) {
    instance.listen<T>(listener);
  }

  /// Fires an event to all registered listeners.
  ///
  /// All listeners registered for the event type [T] will be executed.
  /// Listeners marked with `once = true` will be automatically removed
  /// after handling the event.
  ///
  /// If a listener throws an error, the [onError] handler will be called
  /// (if set), and execution will continue with the next listener.
  ///
  /// ```dart
  /// await MayrEvents.fire(UserRegisteredEvent('user123', 'user@example.com'));
  /// ```
  Future<void> fire<T extends MayrEvent>(T event) async {
    final listeners = _listeners[T] ?? [];

    // Create a copy to avoid concurrent modification issues
    for (final listener in List<MayrListener>.of(listeners)) {
      // Run beforeHandle hook if provided
      if (beforeHandle != null) {
        await beforeHandle!(event, listener);
      }

      try {
        // Execute listener in isolate or main thread
        if (listener.runInIsolate) {
          await Isolate.run(() => listener.handle(event as T));
        } else {
          await listener.handle(event as T);
        }

        // Remove once-only listeners after successful execution
        if (listener.once) {
          _listeners[T]?.remove(listener);
        }
      } catch (e, s) {
        // Call error handler if provided
        if (onError != null) {
          await onError!(event, e, s);
        }
      }
    }
  }

  /// Removes a specific listener for an event type.
  ///
  /// ```dart
  /// final listener = SendWelcomeEmailListener();
  /// MayrEvents.on<UserRegisteredEvent>(listener);
  ///
  /// // Later...
  /// MayrEvents.instance.remove<UserRegisteredEvent>(listener);
  /// ```
  void remove<T extends MayrEvent>(MayrListener<T> listener) {
    _listeners[T]?.remove(listener);
  }

  /// Removes all listeners for a specific event type.
  ///
  /// ```dart
  /// MayrEvents.instance.removeAll<UserRegisteredEvent>();
  /// ```
  void removeAll<T extends MayrEvent>() {
    _listeners.remove(T);
  }

  /// Clears all registered listeners.
  ///
  /// This is useful for testing or resetting the event bus.
  void clear() {
    _listeners.clear();
  }

  /// Returns the number of listeners registered for an event type.
  ///
  /// ```dart
  /// final count = MayrEvents.instance.listenerCount<UserRegisteredEvent>();
  /// print('$count listeners registered');
  /// ```
  int listenerCount<T extends MayrEvent>() {
    return _listeners[T]?.length ?? 0;
  }

  /// Returns whether any listeners are registered for an event type.
  ///
  /// ```dart
  /// if (MayrEvents.instance.hasListeners<UserRegisteredEvent>()) {
  ///   print('Listeners registered');
  /// }
  /// ```
  bool hasListeners<T extends MayrEvent>() {
    return (_listeners[T]?.isNotEmpty ?? false);
  }
}
