#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Errors that can occur when working with Hybrid Logical Clocks.
public enum HybridLogicalClockError: Error, Sendable {
    /// The timestamp is too far in the future compared to the local clock
    case timestampTooFarInFuture(delta: TimeInterval)
    /// The timestamp is too far in the past compared to the local clock
    case timestampTooFarInPast(delta: TimeInterval)
    /// The clock configuration is invalid
    case invalidConfiguration(String)
}

/// A protocol for providing the current time to a Hybrid Logical Clock.
public protocol TimeProvider: Sendable {
    /// Returns the current time as nanoseconds since epoch
    func currentTimeNanos() -> UInt64
}

/// Default time provider using system time
public struct SystemTimeProvider: TimeProvider, Sendable {
    public init() {}
    
    public func currentTimeNanos() -> UInt64 {
        let timeInterval = Date().timeIntervalSince1970
        return UInt64(timeInterval * 1_000_000_000)
    }
}

/// A Hybrid Logical Clock implementation for generating unique, monotonic timestamps.
///
/// A Hybrid Logical Clock (HLC) combines physical time with logical time to create
/// timestamps that preserve causal ordering across distributed systems. Each timestamp
/// is guaranteed to be unique and monotonically increasing.
///
/// ## Basic Usage
/// ```swift
/// let hlc = HybridLogicalClock()
/// let timestamp1 = hlc.newTimestamp()
/// let timestamp2 = hlc.newTimestamp()
/// assert(timestamp1 < timestamp2)
/// ```
///
/// ## Custom Configuration
/// ```swift
/// let hlc = HybridLogicalClock(
///     id: UUID(),
///     timeProvider: SystemTimeProvider(),
///     maxDelta: 60.0 // 60 seconds max drift
/// )
/// ```
public final class HybridLogicalClock: @unchecked Sendable {
    private let id: UUID
    private let timeProvider: TimeProvider
    private let maxDelta: TimeInterval
    private let lock = NSLock()
    private var _lastTimestamp: Timestamp
    
    /// Creates a new Hybrid Logical Clock with default configuration.
    ///
    /// Uses a random UUID as the identifier, system time provider,
    /// and allows up to 60 seconds of time drift.
    ///
    /// ## Example
    /// ```swift
    /// let hlc = HybridLogicalClock()
    /// let timestamp = hlc.newTimestamp()
    /// print("Generated timestamp: \(timestamp)")
    /// ```
    public convenience init() {
        self.init(
            id: UUID(),
            timeProvider: SystemTimeProvider(),
            maxDelta: 60.0
        )
    }
    
    /// Creates a new Hybrid Logical Clock with custom configuration.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this clock instance
    ///   - timeProvider: Provider for current time values
    ///   - maxDelta: Maximum allowed time drift in seconds
    ///
    /// ## Example
    /// ```swift
    /// let customId = UUID()
    /// let hlc = HybridLogicalClock(
    ///     id: customId,
    ///     timeProvider: SystemTimeProvider(),
    ///     maxDelta: 30.0
    /// )
    /// ```
    public init(id: UUID, timeProvider: TimeProvider, maxDelta: TimeInterval) {
        self.id = id
        self.timeProvider = timeProvider
        self.maxDelta = maxDelta
        
        let currentTime = timeProvider.currentTimeNanos()
        self._lastTimestamp = Timestamp(time: currentTime - 1, logicalTime: 0, id: id)
    }
    
    /// Generates a new unique timestamp.
    ///
    /// The timestamp combines the current physical time with a logical counter
    /// to ensure uniqueness and monotonic ordering.
    ///
    /// ## Example
    /// ```swift
    /// let hlc = HybridLogicalClock()
    /// let ts1 = hlc.newTimestamp()
    /// Thread.sleep(forTimeInterval: 0.001)
    /// let ts2 = hlc.newTimestamp()
    /// assert(ts1 < ts2)
    /// ```
    ///
    /// - Returns: A new unique timestamp
    public func newTimestamp() -> Timestamp {
        lock.lock()
        defer { lock.unlock() }
        
        let currentTime = timeProvider.currentTimeNanos()
        
        let newTimestamp: Timestamp
        if currentTime > _lastTimestamp.time {
            newTimestamp = Timestamp(time: currentTime, logicalTime: 0, id: id)
        } else {
            let nextLogicalTime = _lastTimestamp.logicalTime + 1
            newTimestamp = Timestamp(
                time: _lastTimestamp.time,
                logicalTime: nextLogicalTime,
                id: id
            )
        }
        
        _lastTimestamp = newTimestamp
        return newTimestamp
    }
    
    /// Updates the clock with an external timestamp and returns a new timestamp.
    ///
    /// This method is used to synchronize with timestamps from other clocks
    /// in a distributed system while maintaining causal ordering.
    ///
    /// ## Example
    /// ```swift
    /// let hlc1 = HybridLogicalClock()
    /// let hlc2 = HybridLogicalClock()
    /// 
    /// let ts1 = hlc1.newTimestamp()
    /// let ts2 = try hlc2.updateWithTimestamp(ts1)
    /// assert(ts1 < ts2)
    /// ```
    ///
    /// - Parameter externalTimestamp: The timestamp to update with
    /// - Returns: A new timestamp that incorporates the external timestamp
    /// - Throws: `HybridLogicalClockError` if the timestamp is too far from local time
    public func updateWithTimestamp(_ externalTimestamp: Timestamp) throws -> Timestamp {
        lock.lock()
        defer { lock.unlock() }
        
        let currentTime = timeProvider.currentTimeNanos()
        let externalTime = externalTimestamp.time
        
        let timeDelta = abs(Double(Int64(currentTime) - Int64(externalTime))) / 1_000_000_000
        if timeDelta > maxDelta {
            if currentTime < externalTime {
                throw HybridLogicalClockError.timestampTooFarInFuture(delta: timeDelta)
            } else {
                throw HybridLogicalClockError.timestampTooFarInPast(delta: timeDelta)
            }
        }
        
        let maxTime = max(currentTime, max(_lastTimestamp.time, externalTime))
        
        let newLogicalTime: UInt64
        if maxTime == _lastTimestamp.time && maxTime == externalTime {
            newLogicalTime = max(_lastTimestamp.logicalTime, externalTimestamp.logicalTime) + 1
        } else if maxTime == _lastTimestamp.time {
            newLogicalTime = _lastTimestamp.logicalTime + 1
        } else if maxTime == externalTime {
            newLogicalTime = externalTimestamp.logicalTime + 1
        } else {
            newLogicalTime = 0
        }
        
        let newTimestamp = Timestamp(time: maxTime, logicalTime: newLogicalTime, id: id)
        _lastTimestamp = newTimestamp
        return newTimestamp
    }
    
    /// Returns the last generated timestamp without creating a new one.
    ///
    /// ## Example
    /// ```swift
    /// let hlc = HybridLogicalClock()
    /// let ts1 = hlc.newTimestamp()
    /// let lastTs = hlc.lastTimestamp
    /// assert(ts1 == lastTs)
    /// ```
    ///
    /// - Returns: The most recently generated timestamp
    public var lastTimestamp: Timestamp {
        lock.lock()
        defer { lock.unlock() }
        return _lastTimestamp
    }
    
    /// The unique identifier of this clock instance.
    ///
    /// ## Example
    /// ```swift
    /// let clockId = UUID()
    /// let hlc = HybridLogicalClock(id: clockId, timeProvider: SystemTimeProvider(), maxDelta: 60.0)
    /// assert(hlc.clockId == clockId)
    /// ```
    public var clockId: UUID {
        return id
    }
    
    /// The maximum allowed time drift in seconds.
    ///
    /// ## Example
    /// ```swift
    /// let hlc = HybridLogicalClock()
    /// print("Max drift: \(hlc.maxTimeDrift) seconds")
    /// ```
    public var maxTimeDrift: TimeInterval {
        return maxDelta
    }
}

// MARK: - Convenience Functions

/// Convenience function to create a default HybridLogicalClock
///
/// ## Example
/// ```swift
/// let clock = createClock()
/// let timestamp = clock.newTimestamp()
/// ```
///
/// - Returns: A new HybridLogicalClock with default configuration
public func createClock() -> HybridLogicalClock {
    return HybridLogicalClock()
}

/// Convenience function to create a HybridLogicalClock with custom configuration
///
/// ## Example
/// ```swift
/// let clock = createClock(id: UUID(), maxDelta: 30.0)
/// let timestamp = clock.newTimestamp()
/// ```
///
/// - Parameters:
///   - id: Unique identifier for this clock instance
///   - timeProvider: Provider for current time values (defaults to SystemTimeProvider)
///   - maxDelta: Maximum allowed time drift in seconds (defaults to 60.0)
/// - Returns: A new HybridLogicalClock with the specified configuration
public func createClock(
    id: UUID,
    timeProvider: TimeProvider = SystemTimeProvider(),
    maxDelta: TimeInterval = 60.0
) -> HybridLogicalClock {
    return HybridLogicalClock(id: id, timeProvider: timeProvider, maxDelta: maxDelta)
}