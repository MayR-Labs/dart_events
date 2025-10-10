/// Base class for all events in the Mayr Events system.
///
/// Events are simple, immutable data containers that represent something
/// that has happened in your application.
///
/// ## Example
///
/// ```dart
/// class UserRegisteredEvent extends MayrEvent {
///   final String userId;
///   final String email;
///
///   const UserRegisteredEvent(this.userId, this.email);
/// }
/// ```
abstract class MayrEvent {
  /// Creates a new [MayrEvent].
  ///
  /// Events should be immutable, so all fields should be final.
  const MayrEvent();
}
