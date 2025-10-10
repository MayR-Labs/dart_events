// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
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

/// Event fired when app launches
class AppLaunchedEvent extends MayrEvent {
  const AppLaunchedEvent();
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

/// Sends order confirmation email
class OrderConfirmationListener extends MayrListener<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('📧 Order confirmation sent for ${event.orderId}');
  }
}

/// Tracks app launch (only once)
class TrackAppLaunchListener extends MayrListener<AppLaunchedEvent> {
  @override
  bool get once => true;

  @override
  Future<void> handle(AppLaunchedEvent event) async {
    print('🚀 App launched - Tracked (this runs only once)');
  }
}

// ============================================================================
// 3. Setup Events
// ============================================================================

/// Central event configuration for the app
class MyAppEvents extends MayrEventSetup {
  @override
  void registerListeners() {
    // User registration events
    MayrEvents.on<UserRegisteredEvent>(SendWelcomeEmailListener());
    MayrEvents.on<UserRegisteredEvent>(UserAnalyticsListener());

    // Order events
    MayrEvents.on<OrderPlacedEvent>(ProcessOrderListener());
    MayrEvents.on<OrderPlacedEvent>(OrderConfirmationListener());

    // App lifecycle events
    MayrEvents.on<AppLaunchedEvent>(TrackAppLaunchListener());
  }

  @override
  Future<void> beforeHandle(MayrEvent event, MayrListener listener) async {
    // Log before each listener handles an event
    print(
      '[${DateTime.now().toIso8601String()}] '
      '${listener.runtimeType} handling ${event.runtimeType}',
    );
  }

  @override
  Future<void> onError(MayrEvent event, Object error, StackTrace stack) async {
    // Handle errors from listeners
    print('[ERROR] ${event.runtimeType} failed: $error');
  }
}

// ============================================================================
// 4. Main Application
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize event system
  await MyAppEvents().init();

  // Fire app launched event
  await MayrEvents.instance.fire(const AppLaunchedEvent());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayr Events Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const EventExamplePage(),
    );
  }
}

class EventExamplePage extends StatefulWidget {
  const EventExamplePage({super.key});

  @override
  State<EventExamplePage> createState() => _EventExamplePageState();
}

class _EventExamplePageState extends State<EventExamplePage> {
  int _userCount = 0;
  int _orderCount = 0;

  Future<void> _registerUser() async {
    _userCount++;
    final userId = 'user$_userCount';
    final email = 'user$_userCount@example.com';

    print('\n========================================');
    print('🔥 Firing UserRegisteredEvent');
    print('========================================');

    await MayrEvents.instance.fire(UserRegisteredEvent(userId, email));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User registered: $email'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    _orderCount++;
    final orderId = 'ORD${_orderCount.toString().padLeft(4, '0')}';
    final total = (50 + (_orderCount * 10)).toDouble();

    print('\n========================================');
    print('🔥 Firing OrderPlacedEvent');
    print('========================================');

    await MayrEvents.instance.fire(OrderPlacedEvent(orderId, total));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed: $orderId - \$$total'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fireAppLaunchedAgain() async {
    print('\n========================================');
    print('🔥 Firing AppLaunchedEvent (again)');
    print('========================================');

    await MayrEvents.instance.fire(const AppLaunchedEvent());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App launched event fired (check console)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mayr Events Example'), elevation: 2),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mayr Events Demo',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the buttons below to fire events.\n'
              'Check the console to see listeners in action!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _registerUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Register User'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Triggers:\n'
              '• SendWelcomeEmailListener\n'
              '• UserAnalyticsListener',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _placeOrder,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Place Order'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Triggers:\n'
              '• ProcessOrderListener\n'
              '• OrderConfirmationListener',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _fireAppLaunchedAgain,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Fire App Launched Event'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Triggers:\n'
              '• TrackAppLaunchListener (once only)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Multiple listeners can handle the same event\n'
                      '• Listeners run asynchronously\n'
                      '• once=true listeners run only once\n'
                      '• Check your console for detailed logs',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
