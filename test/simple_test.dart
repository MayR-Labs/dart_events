// ignore_for_file: avoid_print

import 'dart:async';
import 'package:mayr_events/mayr_events.dart';

// Simple test events
class TestEvent extends MayrEvent {
  final String message;
  const TestEvent(this.message);
}

class CounterEvent extends MayrEvent {
  const CounterEvent();
}

// Simple test listeners
class TestListener extends MayrListener<TestEvent> {
  final List<String> messages = [];

  @override
  Future<void> handle(TestEvent event) async {
    messages.add(event.message);
  }
}

class CounterListener extends MayrListener<CounterEvent> {
  int count = 0;

  @override
  Future<void> handle(CounterEvent event) async {
    count++;
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

// Test setup
class SimpleTestEvents extends MayrEvents {
  final List<String> logs = [];
  final CounterListener counterListener = CounterListener();

  @override
  void registerListeners() {
    on<CounterEvent>(counterListener);
  }

  @override
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
    logs.add('${listener.runtimeType}->${event.runtimeType}');
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
  static SimpleTestEvents get testInstance => _globalInstance as SimpleTestEvents;
}

void main() async {
  print('🧪 Running Mayr Events Tests...\n');

  // Initialize the events system
  SimpleTestEvents();

  int passed = 0;
  int failed = 0;

  Future<void> test(String name, Future<void> Function() testFn) async {
    try {
      // Reset before each test
      SimpleTestEvents.testInstance.clear();

      await testFn();
      print('✅ $name');
      passed++;
    } catch (e, stack) {
      print('❌ $name');
      print('   Error: $e');
      print('   Stack: $stack');
      failed++;
    }
  }

  // Test 1: Basic event firing
  await test('Basic event firing', () async {
    final listener = TestListener();
    SimpleTestEvents.testInstance.on<TestEvent>(listener);
    await MayrEvents.fire(const TestEvent('hello'));

    if (listener.messages.length != 1) {
      throw Exception('Expected 1 message, got ${listener.messages.length}');
    }
    if (listener.messages[0] != 'hello') {
      throw Exception('Expected "hello", got "${listener.messages[0]}"');
    }
  });

  // Test 2: Multiple listeners
  await test('Multiple listeners for same event', () async {
    final listener1 = TestListener();
    final listener2 = TestListener();

    SimpleTestEvents.testInstance.on<TestEvent>(listener1);
    SimpleTestEvents.testInstance.on<TestEvent>(listener2);

    await MayrEvents.fire(const TestEvent('broadcast'));

    if (listener1.messages.length != 1 || listener2.messages.length != 1) {
      throw Exception('Both listeners should have received the event');
    }
  });

  // Test 3: Once-only listeners
  await test('Once-only listeners', () async {
    final listener = OnceListener();
    SimpleTestEvents.testInstance.on<TestEvent>(listener);

    await MayrEvents.fire(const TestEvent('first'));
    await MayrEvents.fire(const TestEvent('second'));

    if (listener.callCount != 1) {
      throw Exception('Expected 1 call, got ${listener.callCount}');
    }
  });

  // Test 4: Static on() method
  await test('Static on() method', () async {
    final listener = TestListener();
    SimpleTestEvents.testInstance.on<TestEvent>(listener);

    await MayrEvents.fire(const TestEvent('via static'));

    if (listener.messages.length != 1) {
      throw Exception('Listener should have received the event');
    }
  });

  // Test 5: Event system with hooks
  await test('Event system with hooks', () async {
    // Fire multiple events
    await MayrEvents.fire(const CounterEvent());
    await MayrEvents.fire(const CounterEvent());

    if (SimpleTestEvents.testInstance.logs.length != 2) {
      throw Exception('Expected 2 log entries, got ${SimpleTestEvents.testInstance.logs.length}');
    }
  });

  // Test 6: Listener count
  await test('Listener count tracking', () async {
    final listener1 = TestListener();
    final listener2 = TestListener();

    if (SimpleTestEvents.testInstance.listenerCount<TestEvent>() != 0) {
      throw Exception('Should start with 0 listeners');
    }

    SimpleTestEvents.testInstance.on<TestEvent>(listener1);
    if (SimpleTestEvents.testInstance.listenerCount<TestEvent>() != 1) {
      throw Exception('Should have 1 listener');
    }

    SimpleTestEvents.testInstance.on<TestEvent>(listener2);
    if (SimpleTestEvents.testInstance.listenerCount<TestEvent>() != 2) {
      throw Exception('Should have 2 listeners');
    }

    SimpleTestEvents.testInstance.remove<TestEvent>(listener1);
    if (SimpleTestEvents.testInstance.listenerCount<TestEvent>() != 1) {
      throw Exception('Should have 1 listener after removal');
    }
  });

  // Test 7: Has listeners check
  await test('Has listeners check', () async {
    if (SimpleTestEvents.testInstance.hasListeners<TestEvent>()) {
      throw Exception('Should not have listeners initially');
    }

    SimpleTestEvents.testInstance.on<TestEvent>(TestListener());
    if (!SimpleTestEvents.testInstance.hasListeners<TestEvent>()) {
      throw Exception('Should have listeners after registration');
    }

    SimpleTestEvents.testInstance.removeAll<TestEvent>();
    if (SimpleTestEvents.testInstance.hasListeners<TestEvent>()) {
      throw Exception('Should not have listeners after removeAll');
    }
  });

  // Test 8: Clear all listeners
  await test('Clear all listeners', () async {
    SimpleTestEvents.testInstance.on<TestEvent>(TestListener());
    SimpleTestEvents.testInstance.on<CounterEvent>(CounterListener());

    SimpleTestEvents.testInstance.clear();

    if (SimpleTestEvents.testInstance.hasListeners<TestEvent>() ||
        SimpleTestEvents.testInstance.hasListeners<CounterEvent>()) {
      throw Exception('All listeners should be cleared');
    }
  });

  // Test 9: Error handling
  await test('Error handling with onError hook', () async {
    final List<String> errorLogs = [];

    SimpleTestEvents.testInstance.setOnError(event, error, stack) async {
      errorLogs.add('${event.runtimeType}:$error');
    });

    // Create a listener that throws an error
    final errorListener = _ErrorListener();
    SimpleTestEvents.testInstance.on<TestEvent>(errorListener);

    await MayrEvents.fire(const TestEvent('test'));

    if (errorLogs.isEmpty) {
      throw Exception('Error should have been logged');
    }
  });

  // Test 10: beforeHandle hook
  await test('beforeHandle hook execution', () async {
    final List<String> logs = [];

    SimpleTestEvents.testInstance.setBeforeHandle(event, listener) async {
      logs.add('${listener.runtimeType}->${event.runtimeType}');
    });

    final listener = TestListener();
    SimpleTestEvents.testInstance.on<TestEvent>(listener);

    await MayrEvents.fire(const TestEvent('test'));

    if (logs.length != 1) {
      throw Exception('beforeHandle should have been called once');
    }
    if (!logs[0].contains('TestListener')) {
      throw Exception('Log should contain listener type');
    }
  });

  print('\n${'=' * 50}');
  print('📊 Test Results:');
  print('   ✅ Passed: $passed');
  if (failed > 0) {
    print('   ❌ Failed: $failed');
  }
  print('=' * 50);

  if (failed > 0) {
    throw Exception('$failed test(s) failed');
  }
}

class _ErrorListener extends MayrListener<TestEvent> {
  @override
  Future<void> handle(TestEvent event) async {
    throw Exception('Test error');
  }
}
