import Testing
@testable import UniqueHybridLogicalClock
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Time Provider Tests")
struct TimeProviderTests {
    
    @Test("System time provider returns current time")
    func systemTimeProviderCurrentTime() {
        let timeProvider = SystemTimeProvider()
        let beforeTime = Date().timeIntervalSince1970 * 1_000_000_000
        let providedTime = Double(timeProvider.currentTimeNanos())
        let afterTime = Date().timeIntervalSince1970 * 1_000_000_000
        
        #expect(providedTime >= beforeTime)
        #expect(providedTime <= afterTime)
    }
    
    @Test("System time provider increases over time")
    func systemTimeProviderIncreases() async {
        let timeProvider = SystemTimeProvider()
        
        let time1 = timeProvider.currentTimeNanos()
        try? await Task.sleep(nanoseconds: 1_000_000)
        let time2 = timeProvider.currentTimeNanos()
        
        #expect(time2 > time1)
    }
    
    @Test("System time provider nanosecond precision")
    func systemTimeProviderNanosecondPrecision() {
        let timeProvider = SystemTimeProvider()
        let time = timeProvider.currentTimeNanos()
        
        #expect(time > 0)
        
        let timeInterval = Double(time) / 1_000_000_000
        let currentTimeInterval = Date().timeIntervalSince1970
        let difference = abs(timeInterval - currentTimeInterval)
        
        #expect(difference < 1.0)
    }
}