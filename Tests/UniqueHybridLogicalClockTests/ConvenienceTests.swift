import Testing
@testable import UniqueHybridLogicalClock
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Convenience Function Tests")
struct ConvenienceTests {
    
    @Test("Create clock with default configuration")
    func createClockDefault() {
        let clock = createClock()
        
        #expect(clock.maxTimeDrift == 60.0)
        
        let timestamp = clock.newTimestamp()
        #expect(timestamp.id == clock.clockId)
    }
    
    @Test("Create clock with custom configuration")
    func createClockCustom() {
        let customId = UUID()
        let customTimeProvider = SystemTimeProvider()
        let customMaxDelta = 30.0
        
        let clock = createClock(
            id: customId,
            timeProvider: customTimeProvider,
            maxDelta: customMaxDelta
        )
        
        #expect(clock.clockId == customId)
        #expect(clock.maxTimeDrift == customMaxDelta)
        
        let timestamp = clock.newTimestamp()
        #expect(timestamp.id == customId)
    }
    
    @Test("Version constant exists")
    func versionConstant() {
        #expect(UniqueHybridLogicalClockVersion == "1.0.0")
    }
}