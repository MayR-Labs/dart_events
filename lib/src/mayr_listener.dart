import 'mayr_event.dart';

/// Base class for event listeners.
///
/// Listeners handle the logic that should be executed when an event is fired.
/// Each listener is strongly typed to a specific event type.
///
/// ## Example
///
/// ```dart
/// class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
///   @override
///   Future<void> handle(UserRegisteredEvent event) async {
///     await EmailService.sendWelcome(event.userId);
///     print('Welcome email sent to ${event.email}');
///   }
/// }
/// ```
abstract class MayrListener<T extends MayrEvent> {
  /// Creates a new [MayrListener].
  const MayrListener();

  /// Whether this listener should only run once per lifecycle.
  ///
  /// If `true`, the listener will be automatically removed after
  /// it handles an event for the first time.
  ///
  /// Defaults to `false`.
  bool get once => false;

  /// Whether this listener should be queued for later execution.
  ///
  /// If `true` and queue system is set up, the listener will be executed
  /// asynchronously in a queue worker. If `false`, it runs immediately.
  ///
  /// Defaults to `false`.
  bool get queued => false;

  /// Whether this listener should run in an isolate.
  ///
  /// If `true`, the listener will be executed in a separate isolate
  /// using `Isolate.run()`. This is useful for CPU-intensive operations.
  ///
  /// **Note:** When running in an isolate, the listener and event must
  /// not capture any context from the main isolate. All data must be
  /// passed through the event.
  ///
  /// Defaults to `false`.
  bool get runInIsolate => false;

  /// The queue name to send this listener's jobs to.
  ///
  /// Only used if [queued] is `true` and queue system is configured.
  /// If the specified queue doesn't exist, the fallback queue is used.
  ///
  /// Returns `null` by default (no specific queue).
  String? get queue => null;

  /// The timeout duration for this listener's execution.
  ///
  /// Only used when [queued] is `true`.
  ///
  /// Defaults to 60 seconds.
  Duration get timeout => const Duration(seconds: 60);

  /// The number of retries allowed if this listener throws an error.
  ///
  /// Only used when [queued] is `true`. Maximum value is 30.
  ///
  /// Defaults to 3.
  int get retries => 3;

  /// Handles the event.
  ///
  /// This is the main method that contains your listener's logic.
  /// It will be called when the associated event is fired.
  ///
  /// The method is async to support asynchronous operations like
  /// network requests or database queries.
  Future<void> handle(T event);
}
