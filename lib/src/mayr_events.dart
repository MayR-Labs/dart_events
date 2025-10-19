import 'dart:async';
import 'dart:isolate';

import 'mayr_event.dart';
import 'mayr_listener.dart';

/// Base class for application event systems.
///
/// Extend this class to create your own event system. The instance
/// is automatically initialized on first use.
///
/// ## Usage
///
/// ```dart
/// class MyEvents extends MayrEvents {
///   static final MyEvents instance = MyEvents._();
///   MyEvents._();
///
///   @override
///   void registerListeners() {
///     on<UserRegisteredEvent>(SendWelcomeEmailListener());
///   }
///
///   static Future<void> fire<T extends MayrEvent>(T event) async {
///     await instance._fire(event);
///   }
/// }
///
/// // Usage - no init() call needed!
/// await MyEvents.fire(UserRegisteredEvent('user@example.com'));
/// ```
abstract class MayrEvents {
  /// Map of event types to their registered listeners.
  final Map<Type, List<MayrListener>> _listeners = {};

  /// Callback to run before each listener handles an event.
  Future<void> Function(MayrEvent event, MayrListener listener)? _beforeHandle;

  /// Global error handler for listener failures.
  Future<void> Function(MayrEvent event, Object error, StackTrace stack)?
      _onError;

  /// Whether this instance has been initialized.
  bool _initialized = false;

  /// Internal fire method that ensures initialization.
  ///
  /// Subclasses should call this from their static fire method.
  Future<void> _fire<T extends MayrEvent>(T event) async {
    if (!_initialized) {
      _init();
    }
    await _fireEvent(event);
  }

  /// Internal initialization method.
  void _init() {
    if (_initialized) return;
    registerListeners();
    _beforeHandle = beforeHandle;
    _onError = onError;
    _initialized = true;
  }

  /// Register all event-listener bindings.
  ///
  /// Override this method to register your listeners.
  void registerListeners();

  /// Hook that runs before every listener handles an event.
  ///
  /// Override this to add custom logic before event handling.
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {}

  /// Global error handler for listener failures.
  ///
  /// Override this to handle errors from listeners.
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {}

  /// Registers a listener for a specific event type.
  void on<T extends MayrEvent>(MayrListener<T> listener) {
    _listeners.putIfAbsent(T, () => []).add(listener);
  }

  /// Internal event firing implementation.
  Future<void> _fireEvent<T extends MayrEvent>(T event) async {
    final listeners = _listeners[T] ?? [];

    for (final listener in List<MayrListener>.of(listeners)) {
      if (_beforeHandle != null) {
        await _beforeHandle!(event, listener);
      }

      try {
        if (listener.runInIsolate) {
          await Isolate.run(() => listener.handle(event));
        } else {
          await listener.handle(event);
        }

        if (listener.once) {
          _listeners[T]?.remove(listener);
        }
      } catch (e, s) {
        if (_onError != null) {
          await _onError!(event, e, s);
        }
      }
    }
  }

  /// Removes a specific listener for an event type.
  void remove<T extends MayrEvent>(MayrListener<T> listener) {
    _listeners[T]?.remove(listener);
  }

  /// Removes all listeners for a specific event type.
  void removeAll<T extends MayrEvent>() {
    _listeners.remove(T);
  }

  /// Clears all registered listeners.
  void clear() {
    _listeners.clear();
    _initialized = false;
  }

  /// Returns the number of listeners registered for an event type.
  int listenerCount<T extends MayrEvent>() {
    return _listeners[T]?.length ?? 0;
  }

  /// Returns whether any listeners are registered for an event type.
  bool hasListeners<T extends MayrEvent>() {
    return (_listeners[T]?.isNotEmpty ?? false);
  }
}
