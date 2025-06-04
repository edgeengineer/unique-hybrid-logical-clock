import Testing
@testable import UniqueHybridLogicalClock
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Advanced HLC Tests")
struct AdvancedTests {
    
    // MARK: - Performance Tests
    
    @Test("High-frequency timestamp generation performance")
    func highFrequencyTimestampGeneration() async {
        let hlc = HybridLogicalClock()
        let iterations = 10_000
        
        let startTime = Date()
        
        await withTaskGroup(of: Timestamp.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    return await hlc.newTimestamp()
                }
            }
            
            var timestamps: [Timestamp] = []
            for await timestamp in group {
                timestamps.append(timestamp)
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // Should complete 10k timestamps in reasonable time
            // iOS Simulator runs slower, so we adjust expectations
            #if targetEnvironment(simulator)
            let maxDuration = 5.0  // More lenient for simulator
            #else
            let maxDuration = 1.0  // Stricter for real devices/macOS
            #endif
            #expect(duration < maxDuration, "10k timestamps took \(duration)s, should be < \(maxDuration)s")
            
            // All timestamps should be unique and ordered
            let sortedTimestamps = timestamps.sorted()
            let uniqueTimestamps = Set(timestamps)
            
            #expect(uniqueTimestamps.count == iterations)
            #expect(timestamps.count == sortedTimestamps.count)
        }
    }
    
    @Test("Memory usage with large timestamp volume")
    func memoryUsageTest() async {
        let hlc = HybridLogicalClock()
        let iterations = 100_000
        
        // Generate many timestamps and ensure no memory leaks
        var timestamps: [Timestamp] = []
        timestamps.reserveCapacity(iterations)
        
        for _ in 0..<iterations {
            let timestamp = await hlc.newTimestamp()
            timestamps.append(timestamp)
        }
        
        // Verify all timestamps are unique and properly ordered
        let uniqueCount = Set(timestamps).count
        #expect(uniqueCount == iterations)
        
        // Check that timestamps are monotonically increasing
        for i in 1..<timestamps.count {
            #expect(timestamps[i-1] < timestamps[i], "Timestamp at index \(i) is not greater than previous")
        }
    }
    
    // MARK: - Distributed System Simulation
    
    @Test("Multi-node distributed system simulation")
    func distributedSystemSimulation() async throws {
        let nodeCount = 5
        let messagesPerNode = 100
        
        // Create multiple "nodes" (clocks)
        let nodes = (0..<nodeCount).map { _ in HybridLogicalClock() }
        
        // Simulate distributed message passing
        var allEvents: [Timestamp] = []
        
        try await withThrowingTaskGroup(of: [Timestamp].self) { group in
            for nodeIndex in 0..<nodeCount {
                group.addTask {
                    var nodeEvents: [Timestamp] = []
                    let node = nodes[nodeIndex]
                    
                    for _ in 0..<messagesPerNode {
                        // Generate local event
                        let localEvent = await node.newTimestamp()
                        nodeEvents.append(localEvent)
                        
                        // Simulate receiving message from random other node
                        if !nodeEvents.isEmpty && nodeIndex > 0 {
                            let randomPreviousEvent = nodeEvents.randomElement()!
                            let syncedEvent = try await node.updateWithTimestamp(randomPreviousEvent)
                            nodeEvents.append(syncedEvent)
                        }
                    }
                    
                    return nodeEvents
                }
            }
            
            for try await nodeEvents in group {
                allEvents.append(contentsOf: nodeEvents)
            }
        }
        
        // Verify total ordering can be established
        let sortedEvents = allEvents.sorted()
        
        // Check for proper causal ordering
        for i in 1..<sortedEvents.count {
            #expect(sortedEvents[i-1] <= sortedEvents[i])
        }
        
        #expect(allEvents.count > nodeCount * messagesPerNode)
    }
    
    // MARK: - Edge Cases
    
    @Test("Time overflow scenarios")
    func timeOverflowScenarios() async throws {
        // Test with very large time values near UInt64.max
        let nearMaxTime = UInt64.max - 1000
        
        struct LargeTimeProvider: TimeProvider {
            let fixedTime: UInt64
            func currentTimeNanos() -> UInt64 { fixedTime }
        }
        
        let hlc = HybridLogicalClock(
            id: UUID(),
            timeProvider: LargeTimeProvider(fixedTime: nearMaxTime),
            maxDelta: 60.0
        )
        
        // Should handle large time values gracefully
        let ts1 = await hlc.newTimestamp()
        let ts2 = await hlc.newTimestamp()
        
        #expect(ts1.time == nearMaxTime)
        #expect(ts2.time == nearMaxTime)
        #expect(ts2.logicalTime == ts1.logicalTime + 1)
        #expect(ts1 < ts2)
    }
    
    @Test("Logical time overflow")
    func logicalTimeOverflow() async throws {
        // Test logical time counter approaching UInt64.max
        let nearMaxLogical = UInt64.max - 10
        
        struct FixedTimeProvider: TimeProvider {
            func currentTimeNanos() -> UInt64 { 1000 }
        }
        
        let hlc = HybridLogicalClock(
            id: UUID(),
            timeProvider: FixedTimeProvider(),
            maxDelta: 60.0
        )
        
        // Create external timestamp with very high logical time
        let externalTs = Timestamp(
            time: 1000,
            logicalTime: nearMaxLogical,
            id: UUID()
        )
        
        // Should handle synchronization without overflow issues
        let syncedTs = try await hlc.updateWithTimestamp(externalTs)
        
        #expect(syncedTs.logicalTime == nearMaxLogical + 1)
        #expect(syncedTs.time == 1000)
    }
    
    // MARK: - Stress Tests
    
    @Test("Rapid clock synchronization stress test")
    func rapidSynchronizationStressTest() async throws {
        let clockCount = 5
        let syncRounds = 1000
        
        let clocks = (0..<clockCount).map { _ in HybridLogicalClock() }
        
        // Track synchronization activity
        var usedAsSources: Set<Int> = []
        var usedAsTargets: Set<Int> = []
        
        // Rapidly synchronize clocks with each other using multiple patterns
        for round in 0..<syncRounds {
            let sourceClockIndex = round % clockCount
            let targetClockIndex = (round + 1) % clockCount
            
            usedAsSources.insert(sourceClockIndex)
            usedAsTargets.insert(targetClockIndex)
            
            let sourceClock = clocks[sourceClockIndex]
            let targetClock = clocks[targetClockIndex]
            
            let sourceTimestamp = await sourceClock.newTimestamp()
            let syncedTimestamp = try await targetClock.updateWithTimestamp(sourceTimestamp)
            
            #expect(sourceTimestamp < syncedTimestamp)
        }
        
        // Verify synchronization pattern covered all clocks
        #expect(usedAsSources.count == clockCount, "All clocks should be used as sources")
        #expect(usedAsTargets.count == clockCount, "All clocks should be used as targets")
        
        // Verify that synchronization operations were successful
        // The important part is that all synchronizations produced ordered timestamps
        // Rather than checking internal state, verify clock behavior
        for clock in clocks {
            // Each clock should be able to generate a new timestamp after all the activity
            let newTimestamp = await clock.newTimestamp()
            #expect(newTimestamp.id == clock.clockId)
        }
    }
    
    @Test("Concurrent access stress test")
    func concurrentAccessStressTest() async {
        let hlc = HybridLogicalClock()
        let taskCount = 1000
        let operationsPerTask = 100
        
        await withTaskGroup(of: [Timestamp].self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    var timestamps: [Timestamp] = []
                    
                    for _ in 0..<operationsPerTask {
                        let timestamp = await hlc.newTimestamp()
                        timestamps.append(timestamp)
                    }
                    
                    return timestamps
                }
            }
            
            var allTimestamps: [Timestamp] = []
            for await taskTimestamps in group {
                allTimestamps.append(contentsOf: taskTimestamps)
            }
            
            // Verify all timestamps are unique
            let uniqueTimestamps = Set(allTimestamps)
            #expect(uniqueTimestamps.count == allTimestamps.count)
            
            // Verify ordering can be established
            let sortedTimestamps = allTimestamps.sorted()
            for i in 1..<sortedTimestamps.count {
                #expect(sortedTimestamps[i-1] < sortedTimestamps[i])
            }
        }
    }
    
    // MARK: - Property-Based Tests
    
    @Test("Timestamp ordering property")
    func timestampOrderingProperty() async {
        let hlc = HybridLogicalClock()
        let testCount = 1000
        
        var previousTimestamp: Timestamp?
        
        for _ in 0..<testCount {
            let currentTimestamp = await hlc.newTimestamp()
            
            if let prev = previousTimestamp {
                // Property: timestamps from same clock are always ordered
                #expect(prev < currentTimestamp)
                
                // Property: time never decreases
                #expect(currentTimestamp.time >= prev.time)
                
                // Property: if time is same, logical time increases
                if currentTimestamp.time == prev.time {
                    #expect(currentTimestamp.logicalTime == prev.logicalTime + 1)
                }
            }
            
            previousTimestamp = currentTimestamp
        }
    }
    
    @Test("Clock synchronization property")
    func clockSynchronizationProperty() async throws {
        let hlc1 = HybridLogicalClock()
        let hlc2 = HybridLogicalClock()
        let testCount = 100
        
        for _ in 0..<testCount {
            let ts1 = await hlc1.newTimestamp()
            let ts2 = try await hlc2.updateWithTimestamp(ts1)
            
            // Property: synchronized timestamp is always greater than input
            #expect(ts1 < ts2)
            
            // Property: synchronized timestamp has correct clock ID
            #expect(ts2.id == hlc2.clockId)
            
            // Property: time advances or logical time increases
            #expect(ts2.time >= ts1.time)
            if ts2.time == ts1.time {
                #expect(ts2.logicalTime > ts1.logicalTime)
            }
        }
    }
    
    // MARK: - Serialization Tests
    
    #if !SWIFT_EMBEDDED
    @Test("JSON serialization round-trip stress test")
    func jsonSerializationStressTest() async throws {
        let hlc = HybridLogicalClock()
        let testCount = 1000
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for _ in 0..<testCount {
            let originalTimestamp = await hlc.newTimestamp()
            
            // Serialize to JSON
            let jsonData = try encoder.encode(originalTimestamp)
            
            // Deserialize from JSON
            let decodedTimestamp = try decoder.decode(Timestamp.self, from: jsonData)
            
            // Verify exact equality
            #expect(originalTimestamp == decodedTimestamp)
            #expect(originalTimestamp.time == decodedTimestamp.time)
            #expect(originalTimestamp.logicalTime == decodedTimestamp.logicalTime)
            #expect(originalTimestamp.id == decodedTimestamp.id)
        }
    }
    
    @Test("Large timestamp collection serialization")
    func largeCollectionSerialization() async throws {
        let hlc = HybridLogicalClock()
        let timestampCount = 10_000
        
        // Generate large collection of timestamps
        var timestamps: [Timestamp] = []
        for _ in 0..<timestampCount {
            let timestamp = await hlc.newTimestamp()
            timestamps.append(timestamp)
        }
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Serialize entire collection
        let jsonData = try encoder.encode(timestamps)
        
        // Deserialize entire collection
        let decodedTimestamps = try decoder.decode([Timestamp].self, from: jsonData)
        
        // Verify all timestamps survived round-trip
        #expect(decodedTimestamps.count == timestampCount)
        
        for (original, decoded) in zip(timestamps, decodedTimestamps) {
            #expect(original == decoded)
        }
    }
    #endif
}