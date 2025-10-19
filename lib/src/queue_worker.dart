import 'dart:async';
import 'dart:collection';

import 'mayr_event.dart';
import 'mayr_listener.dart';

/// A job to be executed in a queue.
class QueueJob<T extends MayrEvent> {
  /// The event to be handled.
  final T event;

  /// The listener that will handle the event.
  final MayrListener<T> listener;

  /// Timeout duration for this job.
  final Duration timeout;

  /// Number of retry attempts allowed.
  final int retries;

  /// Current retry count.
  int currentRetry = 0;

  /// Optional error callback.
  final Future<void> Function(T event, Object error, StackTrace stack)?
      onError;

  /// Creates a new [QueueJob].
  QueueJob({
    required this.event,
    required this.listener,
    required this.timeout,
    required this.retries,
    this.onError,
  });

  /// Returns true if this job can be retried.
  bool get canRetry => currentRetry < retries;

  /// Increments the retry counter.
  void incrementRetry() {
    currentRetry++;
  }
}

/// Manages a queue of jobs and processes them in an isolate.
class QueueWorker {
  /// The name of this queue.
  final String queueName;

  /// The queue of pending jobs.
  final Queue<QueueJob> _queue = Queue<QueueJob>();

  /// Whether the worker is currently processing.
  bool _isProcessing = false;

  /// Completer for tracking when the queue becomes empty.
  Completer<void>? _emptyCompleter;

  /// Creates a new [QueueWorker].
  QueueWorker(this.queueName);

  /// Adds a job to the queue and starts processing if not already running.
  void enqueue(QueueJob job) {
    _queue.add(job);
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// Returns true if the queue is empty.
  bool get isEmpty => _queue.isEmpty && !_isProcessing;

  /// Waits for the queue to become empty.
  Future<void> waitUntilEmpty() {
    if (isEmpty) {
      return Future.value();
    }
    _emptyCompleter ??= Completer<void>();
    return _emptyCompleter!.future;
  }

  /// Processes jobs in the queue.
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();

      try {
        // Execute the job with timeout
        await _executeJob(job);
      } catch (e, stackTrace) {
        // Report the error
        if (job.onError != null) {
          await job.onError!(job.event, e, stackTrace);
        }

        // If error occurs and can retry, push back to queue
        if (job.canRetry) {
          job.incrementRetry();
          _queue.add(job); // Add to back of queue
        }
        // Otherwise, the job is dropped
      }
    }

    _isProcessing = false;
    
    // Notify anyone waiting for empty queue
    if (_emptyCompleter != null && !_emptyCompleter!.isCompleted) {
      _emptyCompleter!.complete();
      _emptyCompleter = null;
    }
  }

  /// Executes a single job with timeout.
  Future<void> _executeJob(QueueJob job) async {
    await job.listener.handle(job.event).timeout(
      job.timeout,
      onTimeout: () {
        throw TimeoutException(
          'Job timed out after ${job.timeout.inSeconds}s',
          job.timeout,
        );
      },
    );
  }
}
