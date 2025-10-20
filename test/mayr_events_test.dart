import 'package:test/test.dart';
import 'package:mayr_events/mayr_events.dart';

// Test events
class TestEvent extends MayrEvent {
  final String message;
  const TestEvent(this.message);
}

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

// Test listeners
class TestListener extends MayrListener<TestEvent> {
  final List<String> messages = [];

  @override
  Future<void> handle(TestEvent event) async {
    messages.add(event.message);
  }
}

class OnceListener extends MayrListener<TestEvent> {
  int callCount = 0;

  @override
  bool get once => true;

  @override
  Future<void> handle(TestEvent event) async {
    callCount++;
  }
}

class ErrorThrowingListener extends MayrListener<TestEvent> {
  @override
  Future<void> handle(TestEvent event) async {
    throw Exception('Test error');
  }
}

class AsyncListener extends MayrListener<TestEvent> {
  final List<String> messages = [];

  @override
  Future<void> handle(TestEvent event) async {
    await Future.delayed(Duration(milliseconds: 10));
    messages.add(event.message);
  }
}

class WelcomeEmailListener extends MayrListener<UserRegisteredEvent> {
  final List<String> sentTo = [];

  @override
  Future<void> handle(UserRegisteredEvent event) async {
    sentTo.add(event.email);
  }
}

class AnalyticsListener extends MayrListener<OrderPlacedEvent> {
  final List<double> totals = [];

  @override
  Future<void> handle(OrderPlacedEvent event) async {
    totals.add(event.total);
  }
}

void main() {
  setUp(() {
    MayrEvents.clear();
  });

  group('MayrEvent', () {
    test('can be created as const', () {
      const event = TestEvent('test');
      expect(event.message, 'test');
    });

    test('supports different event types', () {
      const userEvent = UserRegisteredEvent('user123', 'user@test.com');
      const orderEvent = OrderPlacedEvent('order456', 99.99);

      expect(userEvent.userId, 'user123');
      expect(userEvent.email, 'user@test.com');
      expect(orderEvent.orderId, 'order456');
      expect(orderEvent.total, 99.99);
    });
  });

  group('MayrListener', () {
    test('has default values', () {
      final listener = TestListener();
      expect(listener.once, false);
      expect(listener.queued, false);
      expect(listener.runInIsolate, false);
    });

    test('can override default values', () {
      final listener = OnceListener();
      expect(listener.once, true);
    });
  });

  group('MayrEvents', () {
    test('can register and fire events', () async {
      final listener = TestListener();
      MayrEvents.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('hello'));

      expect(listener.messages, ['hello']);
    });

    test('supports multiple listeners for same event', () async {
      final listener1 = TestListener();
      final listener2 = TestListener();

      MayrEvents.on<TestEvent>(listener1);
      MayrEvents.on<TestEvent>(listener2);

      await MayrEvents.fire(const TestEvent('broadcast'));

      expect(listener1.messages, ['broadcast']);
      expect(listener2.messages, ['broadcast']);
    });

    test('fires events to correct listener type only', () async {
      final testListener = TestListener();
      final userListener = WelcomeEmailListener();

      MayrEvents.on<TestEvent>(testListener);
      MayrEvents.on<UserRegisteredEvent>(userListener);

      await MayrEvents.fire(const TestEvent('test'));
      await MayrEvents.fire(
        const UserRegisteredEvent('u1', 'test@example.com'),
      );

      expect(testListener.messages, ['test']);
      expect(userListener.sentTo, ['test@example.com']);
    });

    test('supports once-only listeners', () async {
      final listener = OnceListener();
      MayrEvents.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('first'));
      await MayrEvents.fire(const TestEvent('second'));

      expect(listener.callCount, 1);
    });

    test('handles listener errors gracefully', () async {
      final errorListener = ErrorThrowingListener();
      final normalListener = TestListener();

      MayrEvents.on<TestEvent>(errorListener);
      MayrEvents.on<TestEvent>(normalListener);

      await MayrEvents.fire(const TestEvent('test'));

      expect(normalListener.messages, ['test']);
    });

    test('calls beforeHandle hook', () async {
      final listener = TestListener();
      final List<String> logs = [];

      MayrEvents.on<TestEvent>(listener);
      MayrEvents.beforeHandle('test', (event, listener) async {
        logs.add('${listener.runtimeType}->${event.runtimeType}');
      });

      await MayrEvents.fire(const TestEvent('test'));

      expect(logs, ['TestListener->TestEvent']);
      expect(listener.messages, ['test']);
    });

    test('calls onError hook', () async {
      final listener = ErrorThrowingListener();
      final List<String> errorLogs = [];

      MayrEvents.on<TestEvent>(listener);
      MayrEvents.onError('test', (event, error, stack) async {
        errorLogs.add('${event.runtimeType}:${error.toString()}');
      });

      await MayrEvents.fire(const TestEvent('test'));

      expect(errorLogs.length, 1);
      expect(errorLogs[0], contains('TestEvent'));
      expect(errorLogs[0], contains('Test error'));
    });

    test('supports shouldHandle callbacks', () async {
      final listener = TestListener();

      MayrEvents.on<TestEvent>(listener);
      MayrEvents.shouldHandle('validator', (event) {
        return event is TestEvent && event.message != 'skip';
      });

      await MayrEvents.fire(const TestEvent('process'));
      await MayrEvents.fire(const TestEvent('skip'));

      expect(listener.messages, ['process']);
    });

    test('can remove handlers', () async {
      final listener = TestListener();
      final List<String> logs = [];

      MayrEvents.on<TestEvent>(listener);
      MayrEvents.beforeHandle('test', (event, listener) async {
        logs.add('logged');
      });

      await MayrEvents.fire(const TestEvent('first'));

      MayrEvents.removeBeforeHandler('test');

      await MayrEvents.fire(const TestEvent('second'));

      expect(logs, ['logged']);
      expect(listener.messages, ['first', 'second']);
    });

    test('supports async listeners', () async {
      final listener = AsyncListener();
      MayrEvents.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('async test'));

      expect(listener.messages, ['async test']);
    });

    test('can remove specific listener', () async {
      final listener = TestListener();
      MayrEvents.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('first'));
      MayrEvents.remove<TestEvent>(listener);
      await MayrEvents.fire(const TestEvent('second'));

      expect(listener.messages, ['first']);
    });

    test('can remove all listeners for event type', () async {
      final listener1 = TestListener();
      final listener2 = TestListener();

      MayrEvents.on<TestEvent>(listener1);
      MayrEvents.on<TestEvent>(listener2);

      await MayrEvents.fire(const TestEvent('first'));
      MayrEvents.removeAll<TestEvent>();
      await MayrEvents.fire(const TestEvent('second'));

      expect(listener1.messages, ['first']);
      expect(listener2.messages, ['first']);
    });

    test('can clear all listeners', () async {
      final testListener = TestListener();
      final userListener = WelcomeEmailListener();

      MayrEvents.on<TestEvent>(testListener);
      MayrEvents.on<UserRegisteredEvent>(userListener);

      MayrEvents.clear();

      await MayrEvents.fire(const TestEvent('test'));
      await MayrEvents.fire(
        const UserRegisteredEvent('u1', 'test@example.com'),
      );

      expect(testListener.messages, isEmpty);
      expect(userListener.sentTo, isEmpty);
    });

    test('can count listeners', () {
      final listener1 = TestListener();
      final listener2 = TestListener();

      expect(MayrEvents.listenerCount<TestEvent>(), 0);

      MayrEvents.on<TestEvent>(listener1);
      expect(MayrEvents.listenerCount<TestEvent>(), 1);

      MayrEvents.on<TestEvent>(listener2);
      expect(MayrEvents.listenerCount<TestEvent>(), 2);

      MayrEvents.remove<TestEvent>(listener1);
      expect(MayrEvents.listenerCount<TestEvent>(), 1);
    });

    test('can check if listeners exist', () {
      expect(MayrEvents.hasListeners<TestEvent>(), false);

      MayrEvents.on<TestEvent>(TestListener());
      expect(MayrEvents.hasListeners<TestEvent>(), true);

      MayrEvents.removeAll<TestEvent>();
      expect(MayrEvents.hasListeners<TestEvent>(), false);
    });
  });

  group('Integration tests', () {
    test('complete workflow with multiple events and listeners', () async {
      final welcomeListener = WelcomeEmailListener();
      final analyticsListener = AnalyticsListener();
      final List<String> beforeHandleLogs = [];

      MayrEvents.on<UserRegisteredEvent>(welcomeListener);
      MayrEvents.on<OrderPlacedEvent>(analyticsListener);
      MayrEvents.beforeHandle('logger', (event, listener) async {
        beforeHandleLogs.add('${listener.runtimeType}->${event.runtimeType}');
      });

      await MayrEvents.fire(const UserRegisteredEvent('u1', 'alice@test.com'));
      await MayrEvents.fire(const OrderPlacedEvent('o1', 49.99));
      await MayrEvents.fire(const UserRegisteredEvent('u2', 'bob@test.com'));
      await MayrEvents.fire(const OrderPlacedEvent('o2', 149.99));

      expect(welcomeListener.sentTo, ['alice@test.com', 'bob@test.com']);
      expect(analyticsListener.totals, [49.99, 149.99]);
      expect(beforeHandleLogs.length, 4);
    });

    test('mixed listener types work together', () async {
      final normalListener = TestListener();
      final onceListener = OnceListener();
      final asyncListener = AsyncListener();

      MayrEvents.on<TestEvent>(normalListener);
      MayrEvents.on<TestEvent>(onceListener);
      MayrEvents.on<TestEvent>(asyncListener);

      await MayrEvents.fire(const TestEvent('first'));
      await MayrEvents.fire(const TestEvent('second'));

      expect(normalListener.messages, ['first', 'second']);
      expect(onceListener.callCount, 1);
      expect(asyncListener.messages, ['first', 'second']);
    });

    test(
      'fires events using runtimeType when generic type is MayrEvent',
      () async {
        final testListener = TestListener();
        final userListener = WelcomeEmailListener();

        MayrEvents.on<TestEvent>(testListener);
        MayrEvents.on<UserRegisteredEvent>(userListener);

        // Simulate getting events from a method that returns MayrEvent
        MayrEvent getEvent(String eventType) {
          if (eventType == 'test') {
            return const TestEvent('runtime type test');
          } else {
            return const UserRegisteredEvent('u1', 'user@test.com');
          }
        }

        // Fire events where the static type is MayrEvent
        final event1 = getEvent('test');
        final event2 = getEvent('user');
        await MayrEvents.fire(event1);
        await MayrEvents.fire(event2);

        // Both listeners should receive their respective events
        expect(testListener.messages, ['runtime type test']);
        expect(userListener.sentTo, ['user@test.com']);
      },
    );

    test('debug mode can be enabled and disabled', () async {
      // Initially debug mode should be enabled (in test/debug mode)
      final testListener = TestListener();
      MayrEvents.on<TestEvent>(testListener);

      // Disable debug mode
      MayrEvents.debugMode(false);
      await MayrEvents.fire(const TestEvent('test1'));

      // Enable debug mode
      MayrEvents.debugMode(true);
      await MayrEvents.fire(const TestEvent('test2'));

      // Test passes if no errors occur
      expect(testListener.messages, ['test1', 'test2']);
    });
  });
}
