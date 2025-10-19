import 'mayr_event.dart';
import 'mayr_events.dart';
import 'mayr_listener.dart';

/// DEPRECATED: Use the new [MayrEvents] pattern instead.
///
/// This class is deprecated and will be removed in a future version.
/// Instead of extending [MayrEventSetup], extend [MayrEvents] directly.
///
/// Old pattern:
/// ```dart
/// class MyEvents extends MayrEventSetup {
///   @override
///   void registerListeners() {
///     MayrEvents.on<UserEvent>(UserListener());
///   }
/// }
/// await MyEvents().init();
/// await MayrEvents.instance.fire(UserEvent());
/// ```
///
/// New pattern:
/// ```dart
/// class MyEvents extends MayrEvents {
///   static final MyEvents instance = MyEvents._();
///   MyEvents._();
///
///   @override
///   void registerListeners() {
///     on<UserEvent>(UserListener());
///   }
///
///   static Future<void> fire<T extends MayrEvent>(T event) async {
///     await instance._fire(event);
///   }
/// }
/// await MyEvents.fire(UserEvent());
/// ```
@deprecated
abstract class MayrEventSetup {
  /// Creates a new [MayrEventSetup].
  const MayrEventSetup();

  /// Register all event-listener bindings.
  ///
  /// This is where you should register all your listeners.
  /// This method is called during [init].
  void registerListeners();

  /// Hook that runs before every listener handles an event.
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {}

  /// Global error handler for listener failures.
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {}

  /// Initializes the event system.
  ///
  /// DEPRECATED: This method is no longer supported with the new pattern.
  @deprecated
  Future<void> init() async {
    throw UnsupportedError(
      'MayrEventSetup is deprecated. Please use the new MayrEvents pattern.',
    );
  }
}
