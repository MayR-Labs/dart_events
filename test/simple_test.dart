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

class ErrorListener extends MayrListener<TestEvent> {
  @override
  Future<void> handle(TestEvent event) async {
    throw Exception('Test error');
  }
}

void main() async {
  print('🧪 Running Mayr Events Tests...\n');

  int passed = 0;
  int failed = 0;

  Future<void> test(String name, Future<void> Function() testFn) async {
    try {
      MayrEvents.clear();
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
    MayrEvents.on<TestEvent>(listener);
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

    MayrEvents.on<TestEvent>(listener1);
    MayrEvents.on<TestEvent>(listener2);

    await MayrEvents.fire(const TestEvent('broadcast'));

    if (listener1.messages.length != 1 || listener2.messages.length != 1) {
      throw Exception('Both listeners should have received the event');
    }
  });

  // Test 3: Once-only listeners
  await test('Once-only listeners', () async {
    final listener = OnceListener();
    MayrEvents.on<TestEvent>(listener);

    await MayrEvents.fire(const TestEvent('first'));
    await MayrEvents.fire(const TestEvent('second'));

    if (listener.callCount != 1) {
      throw Exception('Expected 1 call, got ${listener.callCount}');
    }
  });

  // Test 4: beforeHandle hook
  await test('beforeHandle hook', () async {
    final listener = TestListener();
    final List<String> logs = [];

    MayrEvents.on<TestEvent>(listener);
    MayrEvents.beforeHandle('test', (event, listener) async {
      logs.add('${listener.runtimeType}->${event.runtimeType}');
    });

    await MayrEvents.fire(const TestEvent('test'));

    if (logs.length != 1) {
      throw Exception('Expected 1 log entry, got ${logs.length}');
    }
  });

  // Test 5: Error handling
  await test('Error handling with onError hook', () async {
    final List<String> errorLogs = [];

    MayrEvents.onError('test', (event, error, stack) async {
      errorLogs.add('${event.runtimeType}:$error');
    });

    final errorListener = ErrorListener();
    MayrEvents.on<TestEvent>(errorListener);

    await MayrEvents.fire(const TestEvent('test'));

    if (errorLogs.isEmpty) {
      throw Exception('Error should have been logged');
    }
  });

  // Test 6: shouldHandle callbacks
  await test('shouldHandle callbacks', () async {
    final listener = TestListener();
    
    MayrEvents.on<TestEvent>(listener);
    MayrEvents.shouldHandle('validator', (event) {
      return event is TestEvent && event.message != 'skip';
    });

    await MayrEvents.fire(const TestEvent('process'));
    await MayrEvents.fire(const TestEvent('skip'));

    if (listener.messages.length != 1) {
      throw Exception('Expected 1 message, got ${listener.messages.length}');
    }
  });

  // Test 7: Listener count
  await test('Listener count tracking', () async {
    final listener1 = TestListener();
    final listener2 = TestListener();

    if (MayrEvents.listenerCount<TestEvent>() != 0) {
      throw Exception('Should start with 0 listeners');
    }

    MayrEvents.on<TestEvent>(listener1);
    if (MayrEvents.listenerCount<TestEvent>() != 1) {
      throw Exception('Should have 1 listener');
    }

    MayrEvents.on<TestEvent>(listener2);
    if (MayrEvents.listenerCount<TestEvent>() != 2) {
      throw Exception('Should have 2 listeners');
    }

    MayrEvents.remove<TestEvent>(listener1);
    if (MayrEvents.listenerCount<TestEvent>() != 1) {
      throw Exception('Should have 1 listener after removal');
    }
  });

  // Test 8: Has listeners check
  await test('Has listeners check', () async {
    if (MayrEvents.hasListeners<TestEvent>()) {
      throw Exception('Should not have listeners initially');
    }

    MayrEvents.on<TestEvent>(TestListener());
    if (!MayrEvents.hasListeners<TestEvent>()) {
      throw Exception('Should have listeners after registration');
    }

    MayrEvents.removeAll<TestEvent>();
    if (MayrEvents.hasListeners<TestEvent>()) {
      throw Exception('Should not have listeners after removeAll');
    }
  });

  // Test 9: Clear all listeners
  await test('Clear all listeners', () async {
    MayrEvents.on<TestEvent>(TestListener());
    MayrEvents.on<CounterEvent>(CounterListener());

    MayrEvents.clear();

    if (MayrEvents.hasListeners<TestEvent>() ||
        MayrEvents.hasListeners<CounterEvent>()) {
      throw Exception('All listeners should be cleared');
    }
  });

  // Test 10: Remove handlers
  await test('Remove handlers', () async {
    final listener = TestListener();
    final List<String> logs = [];

    MayrEvents.on<TestEvent>(listener);
    MayrEvents.beforeHandle('test', (event, listener) async {
      logs.add('logged');
    });

    await MayrEvents.fire(const TestEvent('first'));
    
    MayrEvents.removeBeforeHandler('test');
    
    await MayrEvents.fire(const TestEvent('second'));

    if (logs.length != 1) {
      throw Exception('Expected 1 log, got ${logs.length}');
    }
    if (listener.messages.length != 2) {
      throw Exception('Expected 2 messages, got ${listener.messages.length}');
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
