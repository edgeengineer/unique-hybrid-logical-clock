/// # UniqueHybridLogicalClock
///
/// A Swift implementation of Hybrid Logical Clocks for distributed systems.
/// This library is a port of the Rust [uhlc-rs](https://github.com/atolab/uhlc-rs) library.
///
/// Hybrid Logical Clocks combine physical time with logical counters to provide
/// unique, monotonic timestamps across distributed systems while preserving
/// causal ordering of events.
///
/// ## Key Features
/// - Cross-platform support (macOS, iOS, watchOS, tvOS, visionOS, Linux)
/// - Thread-safe timestamp generation
/// - Configurable time drift tolerance
/// - Full Codable support for serialization
/// - Comprehensive documentation with examples
///
/// ## Quick Start
/// ```swift
/// import UniqueHybridLogicalClock
///
/// let hlc = HybridLogicalClock()
/// let timestamp = hlc.newTimestamp()
/// print("Timestamp: \(timestamp)")
/// ```
///
/// ## Clock Synchronization
/// ```swift
/// let clock1 = HybridLogicalClock()
/// let clock2 = HybridLogicalClock()
///
/// let ts1 = clock1.newTimestamp()
/// let ts2 = try clock2.updateWithTimestamp(ts1)
/// assert(ts1 < ts2)
/// ```
///
/// ## Serialization
/// ```swift
/// let timestamp = hlc.newTimestamp()
/// let data = try JSONEncoder().encode(timestamp)
/// let decoded = try JSONDecoder().decode(Timestamp.self, from: data)
/// ```

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// MARK: - Public API

/// The current version of the UniqueHybridLogicalClock library
public let UniqueHybridLogicalClockVersion = "1.0.0"