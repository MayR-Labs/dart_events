// ignore_for_file: avoid_print

import 'dart:async';
import 'package:mayr_events/mayr_events.dart';

// ============================================================================
// 1. Define Events
// ============================================================================

/// Event fired when a user registers
class UserRegisteredEvent extends MayrEvent {
  final String userId;
  final String email;

  const UserRegisteredEvent(this.userId, this.email);

  /// Example of event-level beforeHandle hook
  @override
  Future<void> Function(MayrEvent, MayrListener)? get beforeHandle =>
      (event, listener) async {
        print('  [Event Hook] About to handle user registration');
      };
}

/// Event fired when an order is placed
class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;

  const OrderPlacedEvent(this.orderId, this.total);
}

// ============================================================================
// 2. Define Listeners
// ============================================================================

/// Sends welcome email when user registers
class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    // Simulate sending email
    await Future.delayed(const Duration(milliseconds: 500));
    print('✅ Welcome email sent to ${event.email}');
  }
}

/// Tracks analytics for user registration
class UserAnalyticsListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    print('📊 Analytics: New user registered - ${event.userId}');
  }
}

/// Processes order and updates inventory
class ProcessOrderListener extends MayrListener<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('📦 Order ${event.orderId} processed - Total: \$${event.total}');
  }
}

// ============================================================================
// 3. Setup Events
// ============================================================================

void setupEvents() {
  // Register listeners
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  MayrEvents.on<UserRegisteredEvent>(UserAnalyticsListener());
  MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());

  // Register global beforeHandle hook
  MayrEvents.beforeHandle('logger', (event, listener) async {
    print('[${DateTime.now().toIso8601String()}] '
        '${listener.runtimeType} handling ${event.runtimeType}');
  });

  // Register global error handler
  MayrEvents.onError('error_logger', (event, error, stack) async {
    print('[ERROR] ${event.runtimeType} failed: $error');
  });

  // Register shouldHandle validator
  MayrEvents.shouldHandle('validator', (event) {
    // Example: only handle events during business hours (always true for demo)
    return true;
  });
}

// ============================================================================
// 4. Main Application
// ============================================================================

Future<void> main() async {
  print('🧪 Mayr Events Example\n');

  // Setup events - this can be done anywhere before firing events
  setupEvents();

  // Example 1: Fire user registered event
  print('========================================');
  print('🔥 Firing UserRegisteredEvent');
  print('========================================');
  await MayrEvents.fire(
    const UserRegisteredEvent('user123', 'user@example.com'),
  );

  print('\n');

  // Example 2: Fire order placed event
  print('========================================');
  print('🔥 Firing OrderPlacedEvent');
  print('========================================');
  await MayrEvents.fire(
    const OrderPlacedEvent('ORD001', 99.99),
  );

  print('\n');

  // Example 3: Demonstrate removing handlers
  print('========================================');
  print('🔥 Removing logger and firing again');
  print('========================================');
  MayrEvents.removeBeforeHandler('logger');
  await MayrEvents.fire(
    const UserRegisteredEvent('user456', 'another@example.com'),
  );

  print('\n✅ Example completed!');
}
