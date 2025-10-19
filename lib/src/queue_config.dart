/// Configuration for queue system.
///
/// Defines available queues, fallback queue, and default timeout.
class QueueConfig {
  /// The fallback queue name to use when a listener's queue is not available.
  final String fallbackQueue;

  /// List of available queue names.
  final List<String> queues;

  /// Default timeout for queue jobs.
  final Duration defaultTimeout;

  /// Creates a new [QueueConfig].
  const QueueConfig({
    required this.fallbackQueue,
    required this.queues,
    this.defaultTimeout = const Duration(seconds: 60),
  });

  /// Returns true if the given queue name is available.
  bool hasQueue(String queueName) {
    return queues.contains(queueName) || queueName == fallbackQueue;
  }

  /// Returns the queue name to use, falling back if necessary.
  String resolveQueue(String? requestedQueue) {
    if (requestedQueue == null || !hasQueue(requestedQueue)) {
      return fallbackQueue;
    }
    return requestedQueue;
  }
}
