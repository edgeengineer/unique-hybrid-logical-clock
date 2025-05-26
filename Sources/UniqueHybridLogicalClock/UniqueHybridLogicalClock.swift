/// UniqueHybridLogicalClock
///
/// A Swift implementation of Hybrid Logical Clocks for distributed systems.
/// This library is a port of the Rust uhlc-rs library.
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

@_exported import Foundation
#if canImport(FoundationEssentials)
@_exported import FoundationEssentials
#endif