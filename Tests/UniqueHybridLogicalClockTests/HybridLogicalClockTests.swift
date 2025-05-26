import Testing
@testable import UniqueHybridLogicalClock
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct MockTimeProvider: TimeProvider {
    private var currentTime: UInt64
    
    init(startTime: UInt64 = 1_000_000_000_000) {
        self.currentTime = startTime
    }
    
    func currentTimeNanos() -> UInt64 {
        return currentTime
    }
    
    mutating func advance(by nanos: UInt64) {
        currentTime += nanos
    }
    
    mutating func setTime(_ time: UInt64) {
        currentTime = time
    }
}

@Suite("Hybrid Logical Clock Tests")
struct HybridLogicalClockTests {
    
    @Test("Default clock initialization")
    func defaultClockInitialization() {
        let hlc = HybridLogicalClock()
        
        #expect(hlc.maxTimeDrift == 60.0)
        #expect(hlc.clockId != UUID())
    }
    
    @Test("Custom clock initialization")
    func customClockInitialization() {
        let id = UUID()
        let timeProvider = SystemTimeProvider()
        let maxDelta = 30.0
        
        let hlc = HybridLogicalClock(id: id, timeProvider: timeProvider, maxDelta: maxDelta)
        
        #expect(hlc.clockId == id)
        #expect(hlc.maxTimeDrift == maxDelta)
    }
    
    @Test("New timestamp generation")
    func newTimestampGeneration() async {
        let mockTime = MockTimeProvider(startTime: 1000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 60.0)
        
        let ts1 = await hlc.newTimestamp()
        #expect(ts1.time == 1000)
        #expect(ts1.logicalTime == 0)
        #expect(ts1.id == hlc.clockId)
    }
    
    @Test("Monotonic timestamp generation with advancing time")
    func monotonicTimestampGenerationAdvancingTime() async {
        let hlc = HybridLogicalClock()
        
        let ts1 = await hlc.newTimestamp()
        
        try? await Task.sleep(nanoseconds: 1_000_000)
        
        let ts2 = await hlc.newTimestamp()
        
        #expect(ts1 < ts2)
        #expect(ts2.time >= ts1.time)
    }
    
    @Test("Logical time increment with same physical time")
    func logicalTimeIncrementSamePhysicalTime() async {
        let mockTime = MockTimeProvider(startTime: 1000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 60.0)
        
        let ts1 = await hlc.newTimestamp()
        let ts2 = await hlc.newTimestamp()
        let ts3 = await hlc.newTimestamp()
        
        #expect(ts1.time == 1000)
        #expect(ts1.logicalTime == 0)
        
        #expect(ts2.time == 1000)
        #expect(ts2.logicalTime == 1)
        
        #expect(ts3.time == 1000)
        #expect(ts3.logicalTime == 2)
        
        #expect(ts1 < ts2)
        #expect(ts2 < ts3)
    }
    
    @Test("Timestamp update with external timestamp from future")
    func timestampUpdateExternalFromFuture() async throws {
        let mockTime = MockTimeProvider(startTime: 1000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 60.0)
        
        let externalId = UUID()
        let externalTimestamp = Timestamp(time: 2000, logicalTime: 5, id: externalId)
        
        let newTimestamp = try await hlc.updateWithTimestamp(externalTimestamp)
        
        #expect(newTimestamp.time == 2000)
        #expect(newTimestamp.logicalTime == 6)
        #expect(newTimestamp.id == hlc.clockId)
    }
    
    @Test("Timestamp update with external timestamp from past")
    func timestampUpdateExternalFromPast() async throws {
        let mockTime = MockTimeProvider(startTime: 2000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 60.0)
        
        _ = await hlc.newTimestamp()
        
        let externalId = UUID()
        let externalTimestamp = Timestamp(time: 1000, logicalTime: 5, id: externalId)
        
        let newTimestamp = try await hlc.updateWithTimestamp(externalTimestamp)
        
        #expect(newTimestamp.time == 2000)
        #expect(newTimestamp.logicalTime == 1)
        #expect(newTimestamp.id == hlc.clockId)
    }
    
    @Test("Timestamp update with same time different logical time")
    func timestampUpdateSameTimeDifferentLogical() async throws {
        let mockTime = MockTimeProvider(startTime: 1000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 60.0)
        
        _ = await hlc.newTimestamp()
        _ = await hlc.newTimestamp()
        
        let externalId = UUID()
        let externalTimestamp = Timestamp(time: 1000, logicalTime: 10, id: externalId)
        
        let newTimestamp = try await hlc.updateWithTimestamp(externalTimestamp)
        
        #expect(newTimestamp.time == 1000)
        #expect(newTimestamp.logicalTime == 11)
        #expect(newTimestamp.id == hlc.clockId)
    }
    
    @Test("Timestamp too far in future error")
    func timestampTooFarInFutureError() async {
        let mockTime = MockTimeProvider(startTime: 1000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 1.0)
        
        let externalId = UUID()
        let futureTime = 1000 + UInt64(2.0 * 1_000_000_000)
        let externalTimestamp = Timestamp(time: futureTime, logicalTime: 0, id: externalId)
        
        await #expect(throws: HybridLogicalClockError.self) {
            try await hlc.updateWithTimestamp(externalTimestamp)
        }
    }
    
    @Test("Timestamp too far in past error")
    func timestampTooFarInPastError() async {
        let mockTime = MockTimeProvider(startTime: 3_000_000_000_000)
        let hlc = HybridLogicalClock(id: UUID(), timeProvider: mockTime, maxDelta: 1.0)
        
        let externalId = UUID()
        let pastTime = UInt64(1_000_000_000_000)
        let externalTimestamp = Timestamp(time: pastTime, logicalTime: 0, id: externalId)
        
        await #expect(throws: HybridLogicalClockError.self) {
            try await hlc.updateWithTimestamp(externalTimestamp)
        }
    }
    
    @Test("Last timestamp retrieval")
    func lastTimestampRetrieval() async {
        let hlc = HybridLogicalClock()
        
        let ts1 = await hlc.newTimestamp()
        let lastTs = await hlc.getLastTimestamp()
        
        #expect(ts1 == lastTs)
        
        let ts2 = await hlc.newTimestamp()
        let newLastTs = await hlc.getLastTimestamp()
        
        #expect(ts2 == newLastTs)
        #expect(newLastTs != lastTs)
    }
    
    @Test("Multiple clocks generate unique timestamps")
    func multipleClocksUniqueTimestamps() async {
        let hlc1 = HybridLogicalClock()
        let hlc2 = HybridLogicalClock()
        
        let ts1 = await hlc1.newTimestamp()
        let ts2 = await hlc2.newTimestamp()
        
        #expect(ts1.id != ts2.id)
        #expect(ts1 != ts2)
    }
    
    @Test("Clock synchronization scenario")
    func clockSynchronizationScenario() async throws {
        let hlc1 = HybridLogicalClock()
        let hlc2 = HybridLogicalClock()
        
        let ts1 = await hlc1.newTimestamp()
        
        let ts2 = try await hlc2.updateWithTimestamp(ts1)
        
        #expect(ts1 < ts2)
        #expect(ts2.id == hlc2.clockId)
        
        let ts3 = await hlc1.newTimestamp()
        let ts4 = try await hlc1.updateWithTimestamp(ts2)
        
        #expect(ts1 < ts2)
        #expect(ts2 < ts3)
        #expect(ts3 < ts4)
    }
    
    @Test("Concurrent timestamp generation")
    func concurrentTimestampGeneration() async {
        let hlc = HybridLogicalClock()
        let taskCount = 100
        
        await withTaskGroup(of: Timestamp.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    return await hlc.newTimestamp()
                }
            }
            
            var timestamps: [Timestamp] = []
            for await timestamp in group {
                timestamps.append(timestamp)
            }
            
            let sortedTimestamps = timestamps.sorted()
            
            for i in 0..<(sortedTimestamps.count - 1) {
                #expect(sortedTimestamps[i] < sortedTimestamps[i + 1])
            }
            
            let uniqueTimestamps = Set(timestamps)
            #expect(uniqueTimestamps.count == taskCount)
        }
    }
}