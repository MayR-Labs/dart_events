import 'dart:async';
import 'dart:isolate';

import 'mayr_event.dart';
import 'mayr_listener.dart';
import 'queue_config.dart';
import 'queue_worker.dart';

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

  /// Queue configuration for the event system.
  QueueConfig? _queueConfig;

  /// Active queue workers.
  final Map<String, QueueWorker> _queueWorkers = {};

  /// Debug mode flag for printing debug information.
  /// Defaults to true when assertions are enabled (debug mode).
  bool _debugMode = _defaultDebugMode;

  /// Default debug mode based on whether assertions are enabled.
  static bool get _defaultDebugMode {
    bool debugMode = false;
    assert(() {
      debugMode = true;
      return true;
    }());
    return debugMode;
  }

  /// Sets debug mode for printing debug information.
  ///
  /// When enabled, prints key actions to help with debugging.
  /// Defaults to true when assertions are enabled (debug mode).
  ///
  /// ```dart
  /// MayrEvents.debugMode(true); // Enable debug output
  /// MayrEvents.debugMode(false); // Disable debug output
  /// ```
  static void debugMode(bool enabled) {
    _instance._debugMode = enabled;
  }

  /// Prints debug messages with the [MayrEvents] prefix.
  ///
  /// Only prints when debug mode is enabled.
  ///
  /// ```dart
  /// MayrEvents.debugPrint('Custom debug message');
  /// ```
  static void debugPrint(String message) {
    if (_instance._debugMode) {
      print('[MayrEvents] - $message');
    }
  }

  /// Registers a listener for a specific event type.
  ///
  /// ```dart
  /// MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  /// ```
  static void on<T extends MayrEvent>(MayrListener<T> listener) {
    _instance._listeners.putIfAbsent(T, () => []).add(listener);
    debugPrint('Registered listener ${listener.runtimeType} for event type $T');
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

  /// Sets up the queue system for queued listeners.
  ///
  /// ```dart
  /// MayrEvents.setupQueue(
  ///   fallbackQueue: 'default',
  ///   queues: ['emails', 'notifications', 'analytics'],
  ///   defaultTimeout: Duration(seconds: 60),
  /// );
  /// ```
  static void setupQueue({
    required String fallbackQueue,
    required List<String> queues,
    Duration defaultTimeout = const Duration(seconds: 60),
  }) {
    _instance._queueConfig = QueueConfig(
      fallbackQueue: fallbackQueue,
      queues: queues,
      defaultTimeout: defaultTimeout,
    );
  }

  /// Fires an event to all registered listeners.
  ///
  /// ```dart
  /// await MayrEvents.fire(UserRegisteredEvent('user123', 'user@example.com'));
  /// ```
  static Future<void> fire<T extends MayrEvent>(T event) async {
    final eventType = event.runtimeType;
    final listeners = _instance._listeners[eventType] ?? [];
    debugPrint('Firing event $eventType to ${listeners.length} listener(s)');

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
        // Check if listener should be queued
        if (listener.queued) {
          await _instance._handleQueuedListener(event, listener);
        } else {
          // Execute listener in isolate or main thread
          if (listener.runInIsolate) {
            await Isolate.run(() => listener.handle(event));
          } else {
            await listener.handle(event);
          }
        }

        // Remove once-only listeners after successful execution
        if (listener.once) {
          _instance._listeners[eventType]?.remove(listener);
          debugPrint('Removed once-only listener ${listener.runtimeType}');
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
    debugPrint('Removed listener ${listener.runtimeType} for event type $T');
  }

  /// Removes all listeners for a specific event type.
  static void removeAll<T extends MayrEvent>() {
    final count = _instance._listeners[T]?.length ?? 0;
    _instance._listeners.remove(T);
    debugPrint('Removed all $count listener(s) for event type $T');
  }

  /// Clears all registered listeners and handlers.
  static void clear() {
    final totalListeners = _instance._listeners.values.fold<int>(
      0,
      (sum, listeners) => sum + listeners.length,
    );
    _instance._listeners.clear();
    _instance._beforeHandlers.clear();
    _instance._errorHandlers.clear();
    _instance._shouldHandlers.clear();
    _instance._queueConfig = null;
    _instance._queueWorkers.clear();
    debugPrint('Cleared all listeners and handlers (total: $totalListeners)');
  }

  /// Returns the number of listeners registered for an event type.
  static int listenerCount<T extends MayrEvent>() {
    return _instance._listeners[T]?.length ?? 0;
  }

  /// Returns whether any listeners are registered for an event type.
  static bool hasListeners<T extends MayrEvent>() {
    return (_instance._listeners[T]?.isNotEmpty ?? false);
  }

  /// Handles a queued listener by adding it to the appropriate queue.
  Future<void> _handleQueuedListener<T extends MayrEvent>(
    T event,
    MayrListener<T> listener,
  ) async {
    if (_queueConfig == null) {
      throw StateError(
        'Queue system not configured. Call MayrEvents.setupQueue() first.',
      );
    }

    // Resolve which queue to use
    final queueName = _queueConfig!.resolveQueue(listener.queue);

    // Get or create queue worker
    final worker = _queueWorkers.putIfAbsent(
      queueName,
      () => QueueWorker(queueName),
    );

    // Clamp retries to max 30
    final retries = listener.retries.clamp(0, 30);

    // Create error handler that calls both event and global error handlers
    Future<void> handleError(T evt, Object error, StackTrace stack) async {
      // Run event-level error handler if it exists
      if (event.onError != null) {
        await event.onError!(evt, error, stack);
      }

      // Run global error handlers
      for (final callback in _errorHandlers.values) {
        await callback(evt, error, stack);
      }
    }

    // Create and enqueue job
    final job = QueueJob<T>(
      event: event,
      listener: listener,
      timeout: listener.timeout,
      retries: retries,
      onError: handleError,
    );

    worker.enqueue(job);

    // Schedule cleanup of empty workers
    _scheduleWorkerCleanup(queueName);
  }

  /// Schedules cleanup of a queue worker if it becomes empty.
  void _scheduleWorkerCleanup(String queueName) {
    final worker = _queueWorkers[queueName];
    if (worker == null) return;

    // Wait for worker to be empty, then remove it
    worker.waitUntilEmpty().then((_) {
      if (worker.isEmpty) {
        _queueWorkers.remove(queueName);
      }
    });
  }
}
