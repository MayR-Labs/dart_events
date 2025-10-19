import 'package:flutter_test/flutter_test.dart';
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

// Test setup
class TestEvents extends MayrEvents {
  final List<String> beforeHandleLogs = [];
  final List<String> errorLogs = [];

  final WelcomeEmailListener welcomeListener = WelcomeEmailListener();
  final AnalyticsListener analyticsListener = AnalyticsListener();

  @override
  void registerListeners() {
    on<UserRegisteredEvent>(welcomeListener);
    on<OrderPlacedEvent>(analyticsListener);
  }

  @override
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
    beforeHandleLogs.add('${listener.runtimeType}->${event.runtimeType}');
  }

  @override
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
    errorLogs.add('${event.runtimeType}:$error');
  }

  // Helper method to set beforeHandle dynamically for testing
  void setBeforeHandle(Future<void> Function(MayrEvent, MayrListener)? handler) {
    _beforeHandle = handler;
  }

  // Helper method to set onError dynamically for testing
  void setOnError(Future<void> Function(MayrEvent, Object, StackTrace)? handler) {
    _onError = handler;
  }

  // Helper to get the test instance
  static TestEvents get testInstance => _globalInstance as TestEvents;
}

void main() {
  // Reset the event bus before each test
  setUp(() {
    TestEvents(); // Create new instance
    TestEvents.testInstance.clear();
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
      expect(listener.queued, true);
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
      TestEvents.testInstance.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('hello'));

      expect(listener.messages, ['hello']);
    });

    test('supports multiple listeners for same event', () async {
      final listener1 = TestListener();
      final listener2 = TestListener();

      TestEvents.testInstance.on<TestEvent>(listener1);
      TestEvents.testInstance.on<TestEvent>(listener2);

      await MayrEvents.fire(const TestEvent('broadcast'));

      expect(listener1.messages, ['broadcast']);
      expect(listener2.messages, ['broadcast']);
    });

    test('fires events to correct listener type only', () async {
      final testListener = TestListener();
      final userListener = WelcomeEmailListener();

      TestEvents.testInstance.on<TestEvent>(testListener);
      TestEvents.testInstance.on<UserRegisteredEvent>(userListener);

      await MayrEvents.fire(const TestEvent('test'));
      await MayrEvents.fire(
        const UserRegisteredEvent('u1', 'test@example.com'),
      );

      expect(testListener.messages, ['test']);
      expect(userListener.sentTo, ['test@example.com']);
    });

    test('supports once-only listeners', () async {
      final listener = OnceListener();
      TestEvents.testInstance.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('first'));
      await MayrEvents.fire(const TestEvent('second'));

      expect(listener.callCount, 1);
    });

    test('handles listener errors gracefully', () async {
      final errorListener = ErrorThrowingListener();
      final normalListener = TestListener();

      TestEvents.testInstance.on<TestEvent>(errorListener);
      TestEvents.testInstance.on<TestEvent>(normalListener);

      // Should not throw despite error listener
      await MayrEvents.fire(const TestEvent('test'));

      // Normal listener should still execute
      expect(normalListener.messages, ['test']);
    });

    test('calls beforeHandle hook', () async {
      final listener = TestListener();
      final List<String> logs = [];

      TestEvents.testInstance.on<TestEvent>(listener);
      TestEvents.testInstance.setBeforeHandle((event, listener) async {
        logs.add('${listener.runtimeType}->${event.runtimeType}');
      });

      await MayrEvents.fire(const TestEvent('test'));

      expect(logs, ['TestListener->TestEvent']);
      expect(listener.messages, ['test']);
    });

    test('calls onError hook', () async {
      final listener = ErrorThrowingListener();
      final List<String> errorLogs = [];

      TestEvents.testInstance.on<TestEvent>(listener);
      TestEvents.testInstance.setOnError((event, error, stack) async {
        errorLogs.add('${event.runtimeType}:${error.toString()}');
      });

      await MayrEvents.fire(const TestEvent('test'));

      expect(errorLogs.length, 1);
      expect(errorLogs[0], contains('TestEvent'));
      expect(errorLogs[0], contains('Test error'));
    });

    test('supports async listeners', () async {
      final listener = AsyncListener();
      TestEvents.testInstance.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('async test'));

      expect(listener.messages, ['async test']);
    });

    test('can use static on() method', () async {
      final listener = TestListener();
      TestEvents.testInstance.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('via static'));

      expect(listener.messages, ['via static']);
    });

    test('can remove specific listener', () async {
      final listener = TestListener();
      TestEvents.testInstance.on<TestEvent>(listener);

      await MayrEvents.fire(const TestEvent('first'));
      TestEvents.testInstance.remove<TestEvent>(listener);
      await MayrEvents.fire(const TestEvent('second'));

      expect(listener.messages, ['first']);
    });

    test('can remove all listeners for event type', () async {
      final listener1 = TestListener();
      final listener2 = TestListener();

      TestEvents.testInstance.on<TestEvent>(listener1);
      TestEvents.testInstance.on<TestEvent>(listener2);

      await MayrEvents.fire(const TestEvent('first'));
      TestEvents.testInstance.removeAll<TestEvent>();
      await MayrEvents.fire(const TestEvent('second'));

      expect(listener1.messages, ['first']);
      expect(listener2.messages, ['first']);
    });

    test('can clear all listeners', () async {
      final testListener = TestListener();
      final userListener = WelcomeEmailListener();

      TestEvents.testInstance.on<TestEvent>(testListener);
      TestEvents.testInstance.on<UserRegisteredEvent>(userListener);

      TestEvents.testInstance.clear();

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

      expect(TestEvents.testInstance.listenerCount<TestEvent>(), 0);

      TestEvents.testInstance.on<TestEvent>(listener1);
      expect(TestEvents.testInstance.listenerCount<TestEvent>(), 1);

      TestEvents.testInstance.on<TestEvent>(listener2);
      expect(TestEvents.testInstance.listenerCount<TestEvent>(), 2);

      TestEvents.testInstance.remove<TestEvent>(listener1);
      expect(TestEvents.testInstance.listenerCount<TestEvent>(), 1);
    });

    test('can check if listeners exist', () {
      expect(TestEvents.testInstance.hasListeners<TestEvent>(), false);

      TestEvents.testInstance.on<TestEvent>(TestListener());
      expect(TestEvents.testInstance.hasListeners<TestEvent>(), true);

      TestEvents.testInstance.removeAll<TestEvent>();
      expect(TestEvents.testInstance.hasListeners<TestEvent>(), false);
    });
  });

  group('Integration tests', () {
    test('complete workflow with multiple events and listeners', () async {
      // Fire multiple events
      await MayrEvents.fire(
        const UserRegisteredEvent('u1', 'alice@test.com'),
      );
      await MayrEvents.fire(const OrderPlacedEvent('o1', 49.99));
      await MayrEvents.fire(
        const UserRegisteredEvent('u2', 'bob@test.com'),
      );
      await MayrEvents.fire(const OrderPlacedEvent('o2', 149.99));

      // Check results
      expect(TestEvents.testInstance.welcomeListener.sentTo, ['alice@test.com', 'bob@test.com']);
      expect(TestEvents.testInstance.analyticsListener.totals, [49.99, 149.99]);
      expect(TestEvents.testInstance.beforeHandleLogs.length, 4);
    });

    test('mixed listener types work together', () async {
      final normalListener = TestListener();
      final onceListener = OnceListener();
      final asyncListener = AsyncListener();

      TestEvents.testInstance.on<TestEvent>(normalListener);
      TestEvents.testInstance.on<TestEvent>(onceListener);
      TestEvents.testInstance.on<TestEvent>(asyncListener);

      await MayrEvents.fire(const TestEvent('first'));
      await MayrEvents.fire(const TestEvent('second'));

      expect(normalListener.messages, ['first', 'second']);
      expect(onceListener.callCount, 1);
      expect(asyncListener.messages, ['first', 'second']);
    });
  });
}
