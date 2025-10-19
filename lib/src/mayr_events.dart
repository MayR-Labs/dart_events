import 'dart:async';
import 'dart:isolate';

import 'mayr_event.dart';
import 'mayr_listener.dart';

/// Global singleton instance of the events system.
MayrEvents? _globalInstance;

/// Base class for application event systems.
///
/// Extend this class to create your own event system. Create a singleton
/// instance and the system will automatically initialize on first use.
///
/// ## Usage
///
/// ```dart
/// class MyEvents extends MayrEvents {
///   @override
///   void registerListeners() {
///     on<UserRegisteredEvent>(SendWelcomeEmailListener());
///   }
/// }
///
/// // Set up your events class (typically in main or before first use)
/// final events = MyEvents();
///
/// // Fire events using the static method
/// await MayrEvents.fire(UserRegisteredEvent('user@example.com'));
/// ```
abstract class MayrEvents {
  /// Creates a MayrEvents instance and sets it as the global instance.
  MayrEvents() {
    _globalInstance = this;
  }

  /// Map of event types to their registered listeners.
  final Map<Type, List<MayrListener>> _listeners = {};

  /// Callback to run before each listener handles an event.
  Future<void> Function(MayrEvent event, MayrListener listener)? _beforeHandle;

  /// Global error handler for listener failures.
  Future<void> Function(MayrEvent event, Object error, StackTrace stack)?
      _onError;

  /// Whether this instance has been initialized.
  bool _initialized = false;

  /// Fires an event to all registered listeners.
  ///
  /// This static method automatically initializes the event system on first use.
  ///
  /// ```dart
  /// await MayrEvents.fire(UserRegisteredEvent('user@example.com'));
  /// ```
  static Future<void> fire<T extends MayrEvent>(T event) async {
    if (_globalInstance == null) {
      throw StateError(
        'No MayrEvents instance has been created. '
        'Please create an instance of your MayrEvents subclass first.',
      );
    }

    if (!_globalInstance!._initialized) {
      _globalInstance!._init();
    }

    await _globalInstance!._fireEvent(event);
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
