import 'dart:async';
import 'mayr_listener.dart';

/// Base class for all events in the Mayr Events system.
///
/// Events are simple, immutable data containers that represent something
/// that has happened in your application.
///
/// Events can optionally define their own hooks for handling logic.
///
/// ## Example
///
/// ```dart
/// class UserRegisteredEvent extends MayrEvent {
///   final String userId;
///   final String email;
///
///   const UserRegisteredEvent(this.userId, this.email);
///
///   @override
///   Future<void> Function(MayrEvent, MayrListener)? get beforeHandle =>
///       (event, listener) async {
///         print('About to handle user registration');
///       };
/// }
/// ```
abstract class MayrEvent {
  /// Creates a new [MayrEvent].
  ///
  /// Events should be immutable, so all fields should be final.
  const MayrEvent();

  /// Optional callback to run before each listener handles this event.
  ///
  /// This is executed before the global beforeHandle callbacks.
  Future<void> Function(MayrEvent event, MayrListener listener)? get beforeHandle => null;

  /// Optional callback to determine if listeners should handle this event.
  ///
  /// If this returns false, the listener will not run.
  /// This is checked before the global shouldHandle callbacks.
  bool Function(MayrEvent event)? get shouldHandle => null;

  /// Optional callback to handle errors when a listener throws an exception.
  ///
  /// This is executed before the global error handlers.
  Future<void> Function(MayrEvent event, Object error, StackTrace stack)? get onError => null;
}
