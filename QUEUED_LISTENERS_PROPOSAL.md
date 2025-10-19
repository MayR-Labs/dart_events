# Queued Listeners Implementation Proposals

## Context

Currently, `MayrListener` has a `queued` property (defaults to `true`) that is not implemented. This proposal outlines different approaches to implement queued listeners that run in a separate isolate to ensure they are non-blocking.

---

## Approach 1: Simple Queue with Dedicated Worker Isolate

### Overview
A single worker isolate processes listener calls from a queue sequentially.

### Architecture
```
Main Isolate                    Worker Isolate
    |                                |
    | -- fire(Event) -->             |
    | add to queue                   |
    | continue immediately           |
    |                                |
    |          <-- SendPort -->      |
    |                                | dequeue item
    |                                | execute listener.handle()
    |                                | repeat
```

### Implementation Details
- Single SendPort/ReceivePort communication channel
- Queue stored in main isolate (List of pending tasks)
- Worker isolate processes tasks one at a time
- Tasks contain: event data, listener reference, and callback info

### Pros
✅ **Simple to implement** - Straightforward queue and isolate management  
✅ **Guaranteed ordering** - Events processed in FIFO order  
✅ **Low overhead** - Single isolate, minimal resource usage  
✅ **Easy debugging** - Sequential processing makes issues easier to trace  
✅ **Predictable behavior** - No race conditions  

### Cons
❌ **Single point of failure** - If worker crashes, entire queue stops  
❌ **No parallelism** - Only one listener executes at a time  
❌ **Potential bottleneck** - Slow listeners block others in queue  
❌ **Memory growth** - Queue can grow unbounded under high load  

### Technical Debts
- Need to handle worker isolate crashes and restart mechanism
- Queue size management and overflow handling not built-in
- No priority system for urgent events
- Difficult to add parallelism later without major refactoring

### Suitable For
- Low to moderate event throughput
- Events that require strict ordering
- Simple use cases with predictable load

---

## Approach 2: Isolate Pool with Work Stealing

### Overview
Multiple worker isolates process events from a shared queue, with work stealing for better load balancing.

### Architecture
```
Main Isolate
    |
    | -- fire(Event) -->
    | add to queue
    | continue immediately
    |
    v
Shared Queue Manager
    |
    +-- Worker 1 (steal from queue)
    +-- Worker 2 (steal from queue)
    +-- Worker 3 (steal from queue)
    +-- Worker N (steal from queue)
```

### Implementation Details
- Pool of N worker isolates (configurable, default: number of processors - 1)
- Central queue manager
- Workers pull tasks when available
- Load balancing through work stealing
- Each worker has its own SendPort/ReceivePort

### Pros
✅ **High throughput** - Multiple listeners execute concurrently  
✅ **Better resource utilization** - Leverages multi-core CPUs  
✅ **Fault tolerant** - Other workers continue if one fails  
✅ **Scalable** - Can adjust pool size based on load  
✅ **Balanced load** - Work stealing prevents idle workers  

### Cons
❌ **Complex implementation** - Requires pool management, load balancing  
❌ **No ordering guarantee** - Events may be processed out of order  
❌ **Higher overhead** - Multiple isolates consume more memory  
❌ **Difficult debugging** - Race conditions and timing issues  
❌ **Resource heavy** - Not suitable for simple use cases  

### Technical Debts
- Complex synchronization needed for queue access
- Worker lifecycle management (creation, health checks, shutdown)
- Potential for resource leaks if workers aren't properly cleaned up
- Configuration tuning required for optimal performance
- Need monitoring/metrics to understand pool health

### Suitable For
- High-throughput applications
- CPU-intensive event processing
- Applications that can tolerate out-of-order processing
- Systems with many independent events

---

## Approach 3: Hybrid - Per-Event-Type Queues with Optional Pooling

### Overview
Each event type gets its own queue. Events can opt into parallel processing or stay sequential.

### Architecture
```
Main Isolate
    |
    | -- fire(UserEvent) --> UserEvent Queue --> Worker 1
    | -- fire(OrderEvent) -> OrderEvent Queue -> Pool (Workers 2,3,4)
    | -- fire(EmailEvent) -> EmailEvent Queue -> Worker 5
```

### Implementation Details
- Separate queue for each event type
- Event types can choose:
  - Single worker (sequential processing)
  - Worker pool (parallel processing)
- Configuration via listener annotation or event property
- Isolate management per queue type

### Pros
✅ **Flexibility** - Mix sequential and parallel processing  
✅ **Event-type isolation** - Slow events don't block others  
✅ **Configurable** - Tune each event type independently  
✅ **Balanced approach** - Complexity only where needed  
✅ **Maintains ordering** - Within each event type  

### Cons
❌ **Medium complexity** - More complex than Approach 1, simpler than 2  
❌ **Resource overhead** - Multiple queues and potentially many isolates  
❌ **Configuration burden** - Users must decide strategy per event type  
❌ **Potential waste** - Unused queues still consume resources  

### Technical Debts
- Need registry to manage per-event-type queues
- Configuration API adds surface area
- Memory overhead from multiple queue structures
- Cleanup of unused event type queues
- Difficult to change strategy dynamically

### Suitable For
- Mixed workloads (some events need ordering, others need speed)
- Applications with distinct event categories
- Teams that want fine-grained control

---

## Approach 4: Async Task Queue (No Isolates)

### Overview
Use Dart's async primitives (Streams, Futures, Completer) instead of isolates. Tasks run asynchronously in the main isolate.

### Architecture
```
Main Isolate
    |
    | -- fire(Event) -->
    | add to StreamController
    | continue immediately
    |
    v
StreamController Queue
    |
    | listen() with async processing
    | await listener.handle(event)
    | process next from stream
```

### Implementation Details
- Use `StreamController` as the queue
- `stream.listen()` with async callback processes events
- No isolates - all processing in main isolate
- Events processed asynchronously but not in parallel

### Pros
✅ **Simplest implementation** - Uses built-in Dart primitives  
✅ **No isolate overhead** - Lower memory usage  
✅ **Easy to debug** - All code in same isolate  
✅ **Good for I/O** - Async works well for network/file operations  
✅ **Guaranteed ordering** - Sequential processing in stream  

### Cons
❌ **Not truly non-blocking** - Still runs on main isolate  
❌ **CPU-bound tasks block** - Heavy computation affects UI/other tasks  
❌ **No parallelism** - Can't utilize multiple cores  
❌ **Doesn't meet requirement** - Issue specifically mentions "separate Isolate"  

### Technical Debts
- Won't scale for CPU-intensive operations
- Can't add true parallelism later without major refactoring
- Main isolate can still be blocked by long-running listeners
- Doesn't leverage multi-core processors

### Suitable For
- I/O-bound operations (network requests, file operations)
- Lightweight event processing
- Applications where CPU usage is not a concern
- **NOT suitable if requirement is strict about isolates**

---

## Recommendation Matrix

| Requirement | Approach 1 | Approach 2 | Approach 3 | Approach 4 |
|------------|-----------|-----------|-----------|-----------|
| Simple implementation | ⭐⭐⭐⭐ | ⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| True non-blocking | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| High throughput | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| Ordering guarantee | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Resource efficiency | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Scalability | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| Easy to maintain | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Production ready | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## My Recommendation: **Approach 1** (with path to Approach 3)

### Why Approach 1?

1. **Meets the requirement** - Uses separate isolate as specified
2. **Right balance** - Simple enough for v2.x, powerful enough for most use cases
3. **Maintainable** - Future developers can understand and modify it
4. **Low risk** - Well-established pattern with predictable behavior
5. **Progressive enhancement** - Can evolve to Approach 3 if needed

### Implementation Plan for Approach 1

```dart
// Phase 1: Core queue system
1. Create QueuedListenerManager class
2. Spawn worker isolate on first queued listener registration
3. Implement SendPort/ReceivePort communication
4. Add queue data structure and task model

// Phase 2: Integration
5. Modify MayrEvents.fire() to check listener.queued property
6. If queued, send to QueuedListenerManager
7. If not queued, execute immediately (current behavior)

// Phase 3: Resilience
8. Add worker health checks and auto-restart
9. Implement queue size limits and overflow handling
10. Add error handling and logging

// Phase 4: Testing & Documentation
11. Unit tests for queue operations
12. Integration tests for queued vs immediate listeners
13. Update documentation and examples
```

### Future Migration Path

- Start with Approach 1 (single worker)
- If performance issues arise, migrate to Approach 3:
  - Add `queueStrategy` property to listeners
  - Create per-event-type queue managers
  - Opt-in to pooling for specific event types
- This migration is straightforward because the API stays the same

---

## Open Questions

1. **Queue size limits?** Should we limit queue size? If yes, what's the overflow strategy?
2. **Timeout handling?** Should queued listeners have execution timeouts?
3. **Priority system?** Do we need high/low priority queues?
4. **Metrics?** Should we expose queue depth, processing time, etc.?
5. **Backpressure?** How do we handle when queue grows faster than processing?
6. **Lifecycle?** When should the worker isolate be created/destroyed?

---

## Example API Usage

```dart
// Listener with queued processing (non-blocking)
class SendEmailListener extends MayrListener<UserRegisteredEvent> {
  @override
  bool get queued => true;  // Runs in worker isolate queue
  
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    await EmailService.send(event.email);
  }
}

// Listener with immediate processing (current behavior)
class UpdateUIListener extends MayrListener<UserRegisteredEvent> {
  @override
  bool get queued => false;  // Runs immediately on main isolate
  
  @override
  Future<void> handle(UserRegisteredEvent event) async {
    // Update UI immediately
  }
}

// Usage remains the same
void main() {
  MayrEvents.on<UserRegisteredEvent>(SendEmailListener());
  MayrEvents.on<UserRegisteredEvent>(UpdateUIListener());
  
  // Both listeners are called, but queued one doesn't block
  await MayrEvents.fire(UserRegisteredEvent('user@example.com'));
}
```

---

## Next Steps

1. **Review this proposal** - Share feedback on preferred approach
2. **Answer open questions** - Clarify requirements and constraints
3. **Approve approach** - Select which approach to implement
4. **Implementation** - I'll implement the chosen approach
5. **Testing & Documentation** - Comprehensive tests and updated docs
