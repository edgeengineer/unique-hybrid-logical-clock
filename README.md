# UniqueHybridLogicalClock

A Swift implementation of Hybrid Logical Clocks for distributed systems. This library is a port of the Rust [uhlc-rs](https://github.com/atolab/uhlc-rs) library.

[![Swift CI](https://github.com/edgeengineer/unique-hybrid-logical-clock/workflows/Swift%20CI/badge.svg)](https://github.com/edgeengineer/unique-hybrid-logical-clock/actions)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS%20%7C%20Linux-lightgrey.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://developer.apple.com/macos/)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![watchOS](https://img.shields.io/badge/watchOS-9.0+-blue.svg)](https://developer.apple.com/watchos/)
[![tvOS](https://img.shields.io/badge/tvOS-16.0+-blue.svg)](https://developer.apple.com/tvos/)
[![visionOS](https://img.shields.io/badge/visionOS-1.0+-blue.svg)](https://developer.apple.com/visionos/)
[![Linux](https://img.shields.io/badge/Linux-Swift%206.0+-red.svg)](https://swift.org)

## Features

- **Cross-platform**: Supports macOS, iOS, watchOS, tvOS, visionOS, Linux, and Swift Embedded
- **Thread-safe**: Uses Swift actors for safe concurrent access (no platform-specific locks)
- **Async/await**: Modern Swift concurrency for optimal performance
- **Configurable**: Customizable time drift tolerance and clock identifiers
- **Serializable**: Full `Codable` support for easy serialization (non-embedded platforms)
- **Well-documented**: Comprehensive DocC documentation with examples

## What are Hybrid Logical Clocks?

Hybrid Logical Clocks (HLC) combine physical time with logical counters to provide unique, monotonic timestamps across distributed systems while preserving causal ordering of events. They solve the problem of event ordering in distributed systems without requiring perfectly synchronized clocks.

## Installation

### Swift Package Manager

Add this package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/edgeengineer/unique-hybrid-logical-clock.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/edgeengineer/unique-hybrid-logical-clock.git`

## Quick Start

### Basic Usage

```swift
import UniqueHybridLogicalClock

// Create a clock with default settings
let hlc = HybridLogicalClock()

// Generate timestamps (async)
let timestamp1 = await hlc.newTimestamp()
let timestamp2 = await hlc.newTimestamp()

// Timestamps are automatically ordered
assert(timestamp1 < timestamp2)

print("Timestamp 1: \(timestamp1)")
print("Timestamp 2: \(timestamp2)")
```

### Custom Configuration

```swift
import UniqueHybridLogicalClock

// Create a clock with custom settings
let customClock = HybridLogicalClock(
    id: UUID(),                    // Custom unique identifier
    timeProvider: SystemTimeProvider(), // Custom time provider
    maxDelta: 60.0                 // Max 60 seconds time drift allowed
)

let timestamp = await customClock.newTimestamp()
```

### Clock Synchronization

```swift
import UniqueHybridLogicalClock

let clock1 = HybridLogicalClock()
let clock2 = HybridLogicalClock()

// Generate a timestamp on clock1
let ts1 = await clock1.newTimestamp()

// Synchronize clock2 with the timestamp from clock1
let ts2 = try await clock2.updateWithTimestamp(ts1)

// The new timestamp preserves causal ordering
assert(ts1 < ts2)
```

### Serialization

```swift
import UniqueHybridLogicalClock
import Foundation

let hlc = HybridLogicalClock()
let timestamp = await hlc.newTimestamp()

// Encode to JSON
let encoder = JSONEncoder()
let data = try encoder.encode(timestamp)

// Decode from JSON
let decoder = JSONDecoder()
let decodedTimestamp = try decoder.decode(Timestamp.self, from: data)

assert(timestamp == decodedTimestamp)
```

### Error Handling

```swift
import UniqueHybridLogicalClock

let hlc = HybridLogicalClock()

do {
    // This might throw if the external timestamp is too far from local time
    let externalTimestamp = Timestamp(time: futureTime, logicalTime: 0, id: UUID())
    let newTimestamp = try await hlc.updateWithTimestamp(externalTimestamp)
} catch HybridLogicalClockError.timestampTooFarInFuture(let delta) {
    print("Timestamp is \(delta) seconds in the future")
} catch HybridLogicalClockError.timestampTooFarInPast(let delta) {
    print("Timestamp is \(delta) seconds in the past")
}
```

## API Overview

### `HybridLogicalClock`

The main clock class that generates unique timestamps:

- `init()` - Creates a clock with default settings
- `init(id:timeProvider:maxDelta:)` - Creates a clock with custom configuration
- `newTimestamp() async` - Generates a new unique timestamp
- `updateWithTimestamp(_:) async throws` - Synchronizes with an external timestamp
- `getLastTimestamp() async` - Returns the last generated timestamp
- `clockId` - The unique identifier of this clock
- `maxTimeDrift` - The maximum allowed time drift

### `Timestamp`

A unique timestamp that combines physical time, logical time, and clock identifier:

- `time` - Physical time as nanoseconds since epoch
- `logicalTime` - Logical counter for ordering events
- `id` - Unique identifier of the generating clock

Timestamps are `Comparable`, `Hashable`, and `Codable`.

### `TimeProvider`

Protocol for providing current time to the clock:

- `SystemTimeProvider` - Uses system time (default implementation)

## Performance Considerations

- Timestamp generation is thread-safe and uses efficient locking
- Memory usage is minimal (each timestamp is ~32 bytes)
- Clock synchronization operations are O(1)
- Suitable for high-frequency timestamp generation

## Platform Support

- **macOS**: 13.0+
- **iOS**: 16.0+
- **watchOS**: 9.0+
- **tvOS**: 16.0+
- **visionOS**: 1.0+
- **Linux**: Swift 6.0+
- **Swift Embedded**: Limited support (see below)

## Swift Embedded Support

UniqueHybridLogicalClock provides **partial support** for Swift Embedded environments:

| Feature | Regular Swift | Swift Embedded | Notes |
|---------|---------------|----------------|-------|
| `Timestamp` struct | ✅ Full support | ✅ Supported | Core functionality available |
| `HybridLogicalClock` class | ✅ Full support | ✅ Supported | Basic clock operations |
| `TimeProvider` protocol | ✅ Full support | ✅ Supported | Custom time sources |
| Thread-safe operations | ✅ Actors | ⚠️ Limited | Single-threaded only |
| Logical clock generation | ✅ Full support | ✅ Supported | Monotonic timestamps |
| `async/await` methods | ✅ Full support | ❌ Not available | No actor support |
| JSON/Codable serialization | ✅ Full support | ❌ Not available | No Foundation |
| `Date`-based time providers | ✅ Full support | ❌ Not available | No Foundation |
| `UUID` support | ✅ Full support | ❌ Not available | Use simple embedded IDs |
| Error throwing | ✅ Full support | ❌ Not available | No Error protocol |

### 🔧 **Swift Embedded Usage**

When using Swift Embedded, the API is synchronous:

```swift
import UniqueHybridLogicalClock

// Create a clock with default settings
let hlc = HybridLogicalClock()

// Generate timestamps (note: synchronous in embedded, async in regular Swift)
let timestamp1 = hlc.newTimestamp()  // or await hlc.newTimestamp() on regular platforms
let timestamp2 = hlc.newTimestamp()

// Timestamps still maintain ordering
assert(timestamp1 < timestamp2)
```

### 📋 **Swift Embedded Considerations**

- **Time Source**: You must provide a custom `TimeProvider` that interfaces with your embedded hardware timers
- **Unique IDs**: Uses simple 128-bit pseudo-random IDs instead of UUIDs
- **Error Handling**: Returns result structs instead of throwing errors
- **No Serialization**: Manual serialization required for persistence
- **Single-threaded**: No actor-based concurrency, suitable for embedded single-threaded environments

## Original Implementation

This library is a Swift port of [uhlc-rs](https://github.com/atolab/uhlc-rs), a Rust implementation of Hybrid Logical Clocks developed by the Eclipse Zenoh team.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## References

- [Hybrid Logical Clocks Paper](https://cse.buffalo.edu/tech-reports/2014-04.pdf)
- [Original Rust Implementation](https://github.com/atolab/uhlc-rs)
- [Eclipse Zenoh](https://zenoh.io/)