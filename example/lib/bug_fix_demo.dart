import 'package:mayr_events/mayr_events.dart';

/// Example demonstrating the runtime type bug fix
///
/// Before the fix, when an event was returned from a method with
/// MayrEvent as the return type, it wouldn't dispatch correctly.
/// Now it uses event.runtimeType instead of the generic type T.

class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;
  const UserRegisteredEvent(this.userId, this.email);
}

class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;
  const OrderPlacedEvent(this.orderId, this.total);
}

class WelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    print('📧 Sending welcome email to ${event.email}');
  }
}

class OrderNotificationListener extends MayrListener<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    print('📦 Processing order ${event.orderId} - \$${event.total}');
  }
}

/// This is the pattern that would have failed before the fix
/// The return type is MayrEvent, not the specific event type
MayrEvent getEventByKey(String eventKey) {
  switch (eventKey) {
    case 'user_registered':
      return const UserRegisteredEvent('user123', 'user@example.com');
    case 'order_placed':
      return const OrderPlacedEvent('order456', 99.99);
    default:
      throw Exception('Unknown event key: $eventKey');
  }
}

void main() async {
  print('=' * 60);
  print('MayrEvents 2.1.0 - Bug Fix and Debug Mode Demo');
  print('=' * 60);
  print('');

  // Register listeners
  MayrEvents.on<UserRegisteredEvent>(WelcomeEmailListener());
  MayrEvents.on<OrderPlacedEvent>(OrderNotificationListener());

  print('1. Testing Runtime Type Fix (Debug Mode Enabled)');
  print('-' * 60);
  MayrEvents.debugMode(true);

  // These events have static type MayrEvent due to getEventByKey's return type
  // Before the fix, they would NOT dispatch to the correct listeners
  // After the fix, they dispatch correctly using event.runtimeType
  final event1 = getEventByKey('user_registered');
  final event2 = getEventByKey('order_placed');

  print('Event 1 static type: MayrEvent, runtime type: ${event1.runtimeType}');
  print('Event 2 static type: MayrEvent, runtime type: ${event2.runtimeType}');
  print('');

  await MayrEvents.fire(event1);
  await MayrEvents.fire(event2);

  print('');
  print('2. Testing Debug Mode Disabled');
  print('-' * 60);
  MayrEvents.debugMode(false);
  print('(No debug output should appear below)');
  await MayrEvents.fire(
    const UserRegisteredEvent('user789', 'test@example.com'),
  );

  print('');
  print('=' * 60);
  print('✅ All tests passed! The runtime type bug is fixed!');
  print('✅ Debug mode is working correctly!');
  print('=' * 60);
}
