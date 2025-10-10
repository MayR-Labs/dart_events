import 'mayr_event.dart';
import 'mayr_events.dart';
import 'mayr_listener.dart';

/// Base class for application-level event setup and configuration.
///
/// This is the entry point for configuring your event system.
/// Extend this class to register all your listeners and define
/// global hooks for your application.
///
/// ## Example
///
/// ```dart
/// class MyAppEvents extends MayrEventSetup {
///   @override
///   void registerListeners() {
///     MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
///     MayrEvents.on<OrderPlacedEvent>(OrderAnalyticsListener());
///   }
///
///   @override
///   Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
///     print('[Before] ${listener.runtimeType} handling ${event.runtimeType}');
///   }
///
///   @override
///   Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
///     print('[Error] ${event.runtimeType}: $error');
///   }
/// }
///
/// // In your main()
/// void main() async {
///   await MyAppEvents().init();
///   runApp(MyApp());
/// }
/// ```
abstract class MayrEventSetup {
  /// Creates a new [MayrEventSetup].
  const MayrEventSetup();

  /// Register all event-listener bindings.
  ///
  /// This is where you should register all your listeners.
  /// This method is called during [init].
  ///
  /// ```dart
  /// @override
  /// void registerListeners() {
  ///   MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  ///   MayrEvents.on<OrderPlacedEvent>(OrderAnalyticsListener());
  /// }
  /// ```
  void registerListeners();

  /// Hook that runs before every listener handles an event.
  ///
  /// This is useful for:
  /// - Logging which events are being processed
  /// - Measuring performance
  /// - Implementing middleware-like behavior
  ///
  /// The default implementation does nothing.
  ///
  /// ```dart
  /// @override
  /// Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
  ///   print('[${DateTime.now()}] ${listener.runtimeType} handling ${event.runtimeType}');
  /// }
  /// ```
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {}

  /// Global error handler for listener failures.
  ///
  /// This is called when a listener throws an exception.
  /// Use this to:
  /// - Log errors
  /// - Send error reports
  /// - Implement fallback behavior
  ///
  /// The default implementation does nothing.
  ///
  /// ```dart
  /// @override
  /// Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
  ///   print('[Error] ${event.runtimeType}: $error');
  ///   await ErrorReporter.report(error, stack);
  /// }
  /// ```
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {}

  /// Initializes the event system.
  ///
  /// Call this method in your `main()` function before running your app.
  /// It will:
  /// 1. Register all listeners via [registerListeners]
  /// 2. Set up global hooks ([beforeHandle], [onError])
  ///
  /// ```dart
  /// void main() async {
  ///   await MyAppEvents().init();
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> init() async {
    final events = MayrEvents.instance;

    // Register all listeners
    registerListeners();

    // Set up global hooks
    events.beforeHandle = beforeHandle;
    events.onError = onError;
  }
}
