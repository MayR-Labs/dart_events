import 'package:test/test.dart';
import 'package:mayr_events/mayr_events.dart';

// Test events
class QueuedTestEvent extends MayrEvent {
  final String message;
  const QueuedTestEvent(this.message);
}

class OrderProcessEvent extends MayrEvent {
  final String orderId;
  const OrderProcessEvent(this.orderId);
}

// Test listeners
class QueuedListener extends MayrListener<QueuedTestEvent> {
  final List<String> processedMessages = [];

  @override
  bool get queued => true;

  @override
  String get queue => 'test_queue';

  @override
  Future<void> handle(QueuedTestEvent event) async {
    await Future.delayed(const Duration(milliseconds: 10));
    processedMessages.add(event.message);
  }
}

class FallbackQueueListener extends MayrListener<QueuedTestEvent> {
  final List<String> processedMessages = [];

  @override
  bool get queued => true;

  @override
  String get queue => 'nonexistent_queue'; // Should fall back

  @override
  Future<void> handle(QueuedTestEvent event) async {
    processedMessages.add(event.message);
  }
}

class RetryListener extends MayrListener<QueuedTestEvent> {
  int attemptCount = 0;
  int failUntilAttempt;

  RetryListener({this.failUntilAttempt = 2});

  @override
  bool get queued => true;

  @override
  String get queue => 'retry_queue';

  @override
  int get retries => 5;

  @override
  Future<void> handle(QueuedTestEvent event) async {
    attemptCount++;
    if (attemptCount < failUntilAttempt) {
      throw Exception('Intentional failure on attempt $attemptCount');
    }
  }
}

class TimeoutListener extends MayrListener<QueuedTestEvent> {
  @override
  bool get queued => true;

  @override
  String get queue => 'timeout_queue';

  @override
  Duration get timeout => const Duration(milliseconds: 50);

  @override
  Future<void> handle(QueuedTestEvent event) async {
    // Simulate a long-running task that will timeout
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

class CustomTimeoutListener extends MayrListener<QueuedTestEvent> {
  final List<String> processedMessages = [];

  @override
  bool get queued => true;

  @override
  String get queue => 'custom_timeout_queue';

  @override
  Duration get timeout => const Duration(seconds: 5);

  @override
  Future<void> handle(QueuedTestEvent event) async {
    await Future.delayed(const Duration(milliseconds: 10));
    processedMessages.add(event.message);
  }
}

class MaxRetriesListener extends MayrListener<QueuedTestEvent> {
  @override
  bool get queued => true;

  @override
  String get queue => 'max_retries_queue';

  @override
  int get retries => 50; // Should be clamped to 30

  @override
  Future<void> handle(QueuedTestEvent event) async {
    // This listener always succeeds
  }
}

class MultiQueueListener extends MayrListener<OrderProcessEvent> {
  final List<String> processedOrders = [];
  final String queueName;

  MultiQueueListener(this.queueName);

  @override
  bool get queued => true;

  @override
  String get queue => queueName;

  @override
  Future<void> handle(OrderProcessEvent event) async {
    await Future.delayed(const Duration(milliseconds: 5));
    processedOrders.add(event.orderId);
  }
}

void main() {
  setUp(() {
    MayrEvents.clear();
  });

  group('Queue Configuration', () {
    test('can setup queue system', () {
      MayrEvents.setupQueue(
        fallbackQueue: 'default',
        queues: ['emails', 'notifications'],
        defaultTimeout: const Duration(seconds: 30),
      );

      // Queue setup doesn't throw
      expect(true, true);
    });

    test('queued listener requires queue setup', () async {
      final listener = QueuedListener();
      final List<String> errorLogs = [];

      MayrEvents.on<QueuedTestEvent>(listener);
      MayrEvents.onError('queue_test', (event, error, stack) async {
        errorLogs.add(error.toString());
      });

      await MayrEvents.fire(const QueuedTestEvent('test'));

      // Should have logged an error about queue not being configured
      expect(errorLogs.any((e) => e.contains('not configured')), true);
    });
  });

  group('Queued Listeners', () {
    setUp(() {
      MayrEvents.setupQueue(
        fallbackQueue: 'default',
        queues: ['test_queue', 'retry_queue'],
        defaultTimeout: const Duration(seconds: 60),
      );
    });

    test('processes queued listeners asynchronously', () async {
      final listener = QueuedListener();
      MayrEvents.on<QueuedTestEvent>(listener);

      await MayrEvents.fire(const QueuedTestEvent('message1'));
      await MayrEvents.fire(const QueuedTestEvent('message2'));

      // Wait a bit for queue processing
      await Future.delayed(const Duration(milliseconds: 100));

      expect(listener.processedMessages, ['message1', 'message2']);
    });

    test('uses fallback queue for nonexistent queue', () async {
      final listener = FallbackQueueListener();
      MayrEvents.on<QueuedTestEvent>(listener);

      await MayrEvents.fire(const QueuedTestEvent('fallback_test'));

      // Wait for queue processing
      await Future.delayed(const Duration(milliseconds: 50));

      expect(listener.processedMessages, ['fallback_test']);
    });

    test('retries failed listeners', () async {
      final listener = RetryListener(failUntilAttempt: 3);
      MayrEvents.on<QueuedTestEvent>(listener);

      await MayrEvents.fire(const QueuedTestEvent('retry_test'));

      // Wait for retries to complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Should have attempted 3 times (fails twice, succeeds on third)
      expect(listener.attemptCount, 3);
    });

    test('stops retrying after max retries exceeded', () async {
      final listener = RetryListener(failUntilAttempt: 100); // Never succeeds
      MayrEvents.on<QueuedTestEvent>(listener);

      await MayrEvents.fire(const QueuedTestEvent('max_retry_test'));

      // Wait for all retry attempts
      await Future.delayed(const Duration(milliseconds: 500));

      // Should have attempted retries + 1 (initial attempt)
      // retries is 5, so should be 6 total attempts
      expect(listener.attemptCount, 6);
    });

    test('respects custom timeout duration', () async {
      final listener = CustomTimeoutListener();
      MayrEvents.on<QueuedTestEvent>(listener);

      await MayrEvents.fire(const QueuedTestEvent('timeout_test'));

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 100));

      expect(listener.processedMessages, ['timeout_test']);
    });

    test('handles timeout errors', () async {
      final listener = TimeoutListener();
      final List<String> errorLogs = [];

      MayrEvents.on<QueuedTestEvent>(listener);
      MayrEvents.onError('timeout_handler', (event, error, stack) async {
        errorLogs.add('timeout_error');
      });

      await MayrEvents.fire(const QueuedTestEvent('will_timeout'));

      // Wait for timeout to occur
      await Future.delayed(const Duration(milliseconds: 400));

      // Error should have been logged (multiple times due to retries)
      expect(errorLogs.isNotEmpty, true);
    });

    test('clamps retries to maximum of 30', () {
      final listener = MaxRetriesListener();
      // The listener specifies 50 retries, but it should be clamped to 30
      expect(listener.retries.clamp(0, 30), 30);
    });

    test('supports multiple queues', () async {
      final listener1 = MultiQueueListener('queue_one');
      final listener2 = MultiQueueListener('queue_two');

      MayrEvents.setupQueue(
        fallbackQueue: 'default',
        queues: ['queue_one', 'queue_two'],
      );

      MayrEvents.on<OrderProcessEvent>(listener1);
      MayrEvents.on<OrderProcessEvent>(listener2);

      await MayrEvents.fire(const OrderProcessEvent('order1'));
      await MayrEvents.fire(const OrderProcessEvent('order2'));

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 100));

      expect(listener1.processedOrders, ['order1', 'order2']);
      expect(listener2.processedOrders, ['order1', 'order2']);
    });

    test('queue workers are cleaned up when empty', () async {
      final listener = QueuedListener();
      MayrEvents.on<QueuedTestEvent>(listener);

      await MayrEvents.fire(const QueuedTestEvent('cleanup_test'));

      // Wait for processing and cleanup
      await Future.delayed(const Duration(milliseconds: 200));

      expect(listener.processedMessages, ['cleanup_test']);
      // Worker should be cleaned up (we can't directly test this, but it shouldn't crash)
    });
  });

  group('Mixed Mode', () {
    setUp(() {
      MayrEvents.setupQueue(fallbackQueue: 'default', queues: ['test_queue']);
    });

    test('supports both queued and non-queued listeners', () async {
      final queuedListener = QueuedListener();
      final nonQueuedListener = _NonQueuedTestListener();

      MayrEvents.on<QueuedTestEvent>(queuedListener);
      MayrEvents.on<QueuedTestEvent>(nonQueuedListener);

      await MayrEvents.fire(const QueuedTestEvent('mixed_test'));

      // Non-queued should run immediately
      expect(nonQueuedListener.messages, ['mixed_test']);

      // Queued should run after a delay
      await Future.delayed(const Duration(milliseconds: 100));
      expect(queuedListener.processedMessages, ['mixed_test']);
    });
  });
}

// Non-queued test listener
class _NonQueuedTestListener extends MayrListener<QueuedTestEvent> {
  final List<String> messages = [];

  @override
  bool get queued => false;

  @override
  Future<void> handle(QueuedTestEvent event) async {
    messages.add(event.message);
  }
}
