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
}

/// Event fired when an order is placed
class OrderPlacedEvent extends MayrEvent {
  final String orderId;
  final double total;

  const OrderPlacedEvent(this.orderId, this.total);
}

/// Event fired when a payment is processed
class PaymentProcessedEvent extends MayrEvent {
  final String paymentId;
  final double amount;

  const PaymentProcessedEvent(this.paymentId, this.amount);
}

// ============================================================================
// 2. Define Non-Queued Listeners (Run immediately)
// ============================================================================

/// Tracks analytics for user registration (runs immediately)
class UserAnalyticsListener extends MayrListener<UserRegisteredEvent> {
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    print('📊 [IMMEDIATE] Analytics: New user registered - ${event.userId}');
  }
}

// ============================================================================
// 3. Define Queued Listeners (Run in background queues)
// ============================================================================

/// Sends welcome email when user registers (queued)
class SendWelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  bool get queued => true;

  @override
  String get queue => 'emails';

  @override
  Duration get timeout => const Duration(seconds: 30);

  @override
  int get retries => 3;

  @override
  Future<void> handle(UserRegisteredEvent event) async {
    // Simulate sending email
    await Future.delayed(const Duration(milliseconds: 500));
    print('📧 [QUEUED-emails] Welcome email sent to ${event.email}');
  }
}

/// Processes order and updates inventory (queued)
class ProcessOrderListener extends MayrListener<OrderPlacedEvent> {
  @override
  bool get queued => true;

  @override
  String get queue => 'orders';

  @override
  Duration get timeout => const Duration(seconds: 60);

  @override
  int get retries => 5;

  @override
  Future<void> handle(OrderPlacedEvent event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print(
      '📦 [QUEUED-orders] Order ${event.orderId} processed - Total: \$${event.total}',
    );
  }
}

/// Sends notification about order (queued)
class OrderNotificationListener extends MayrListener<OrderPlacedEvent> {
  @override
  bool get queued => true;

  @override
  String get queue => 'notifications';

  @override
  Future<void> handle(OrderPlacedEvent event) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('🔔 [QUEUED-notifications] Order notification sent');
  }
}

/// Updates accounting system (queued with fallback)
class UpdateAccountingListener extends MayrListener<PaymentProcessedEvent> {
  @override
  bool get queued => true;

  @override
  String get queue => 'nonexistent_queue'; // Will use fallback queue

  @override
  int get retries => 10;

  @override
  Future<void> handle(PaymentProcessedEvent event) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print(
      '💰 [QUEUED-fallback] Accounting updated - Payment: ${event.paymentId}',
    );
  }
}

/// Listener that simulates failures and retries
class ReliablePaymentProcessor extends MayrListener<PaymentProcessedEvent> {
  static int attemptCount = 0;

  @override
  bool get queued => true;

  @override
  String get queue => 'payments';

  @override
  int get retries => 5;

  @override
  Future<void> handle(PaymentProcessedEvent event) async {
    attemptCount++;
    
    // Fail on first two attempts to demonstrate retry
    if (attemptCount < 3) {
      print(
        '❌ [QUEUED-payments] Payment processing failed (attempt $attemptCount)',
      );
      throw Exception('Payment gateway temporarily unavailable');
    }
    
    await Future.delayed(const Duration(milliseconds: 150));
    print('✅ [QUEUED-payments] Payment processed successfully (attempt $attemptCount)');
  }
}

// ============================================================================
// 4. Setup Events
// ============================================================================

void setupEvents() {
  // Setup queue system BEFORE registering queued listeners
  MayrEvents.setupQueue(
    fallbackQueue: 'default',
    queues: ['emails', 'notifications', 'orders', 'payments'],
    defaultTimeout: const Duration(seconds: 60),
  );

  // Register non-queued listeners (run immediately)
  MayrEvents.on<UserRegisteredEvent>(UserAnalyticsListener());

  // Register queued listeners (run in background)
  MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
  MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());
  MayrEvents.on<OrderPlacedEvent>(OrderNotificationListener());
  MayrEvents.on<PaymentProcessedEvent>(UpdateAccountingListener());
  MayrEvents.on<PaymentProcessedEvent>(ReliablePaymentProcessor());

  // Register global error handler
  MayrEvents.onError('error_logger', (event, error, stack) async {
    print('⚠️  [ERROR] ${event.runtimeType} failed: $error');
  });

  // Register global beforeHandle hook
  MayrEvents.beforeHandle('logger', (event, listener) async {
    final mode = listener.queued ? 'QUEUED' : 'IMMEDIATE';
    print(
      '[${DateTime.now().toIso8601String().substring(11, 23)}] '
      '[$mode] ${listener.runtimeType} handling ${event.runtimeType}',
    );
  });
}

// ============================================================================
// 5. Main Application
// ============================================================================

Future<void> main() async {
  print('🚀 Mayr Events - Queued Listeners Example\n');
  print('=' * 70);

  // Setup events - this must be done before firing events
  setupEvents();

  // Example 1: Fire user registered event
  print('\n📢 Example 1: User Registration');
  print('=' * 70);
  await MayrEvents.fire(
    const UserRegisteredEvent('user123', 'user@example.com'),
  );
  print('✓ Event fired (non-queued listeners run immediately)');
  print('  (queued listeners processing in background...)');

  // Example 2: Fire order placed event
  print('\n📢 Example 2: Order Placement');
  print('=' * 70);
  await MayrEvents.fire(const OrderPlacedEvent('ORD001', 99.99));
  print('✓ Event fired (queued listeners processing in background...)');

  // Example 3: Fire payment processed event (demonstrates retry)
  print('\n📢 Example 3: Payment Processing (with retry)');
  print('=' * 70);
  await MayrEvents.fire(const PaymentProcessedEvent('PAY001', 99.99));
  print('✓ Event fired (watch for retry attempts...)');

  // Wait for all queued jobs to complete
  print('\n⏳ Waiting for queued jobs to complete...');
  await Future.delayed(const Duration(seconds: 3));

  print('\n${'=' * 70}');
  print('✅ All examples completed!');
  print('=' * 70);
  
  print('\nKey Features Demonstrated:');
  print('  ✓ Immediate vs. Queued listeners');
  print('  ✓ Multiple queues (emails, notifications, orders, payments)');
  print('  ✓ Fallback queue for undefined queue names');
  print('  ✓ Automatic retry on failure');
  print('  ✓ Custom timeout and retry configuration');
  print('  ✓ Error handling for queued jobs');
}
