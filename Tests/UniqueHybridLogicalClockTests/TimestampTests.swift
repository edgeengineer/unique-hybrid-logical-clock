import Testing
@testable import UniqueHybridLogicalClock
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Timestamp Tests")
struct TimestampTests {
    
    @Test("Timestamp creation with components")
    func timestampCreation() {
        let id = UUID()
        let timestamp = Timestamp(time: 1000, logicalTime: 5, id: id)
        
        #expect(timestamp.time == 1000)
        #expect(timestamp.logicalTime == 5)
        #expect(timestamp.id == id)
    }
    
    @Test("Timestamp comparison by time")
    func timestampComparisonByTime() {
        let id1 = UUID()
        let id2 = UUID()
        
        let ts1 = Timestamp(time: 1000, logicalTime: 0, id: id1)
        let ts2 = Timestamp(time: 2000, logicalTime: 0, id: id2)
        
        #expect(ts1 < ts2)
        #expect(ts2 > ts1)
        #expect(!(ts1 == ts2))
    }
    
    @Test("Timestamp comparison by logical time")
    func timestampComparisonByLogicalTime() {
        let id1 = UUID()
        let id2 = UUID()
        
        let ts1 = Timestamp(time: 1000, logicalTime: 5, id: id1)
        let ts2 = Timestamp(time: 1000, logicalTime: 10, id: id2)
        
        #expect(ts1 < ts2)
        #expect(ts2 > ts1)
        #expect(!(ts1 == ts2))
    }
    
    @Test("Timestamp comparison by ID")
    func timestampComparisonById() {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        
        let ts1 = Timestamp(time: 1000, logicalTime: 5, id: id1)
        let ts2 = Timestamp(time: 1000, logicalTime: 5, id: id2)
        
        #expect(ts1 < ts2)
        #expect(ts2 > ts1)
        #expect(!(ts1 == ts2))
    }
    
    @Test("Timestamp equality")
    func timestampEquality() {
        let id = UUID()
        let ts1 = Timestamp(time: 1000, logicalTime: 5, id: id)
        let ts2 = Timestamp(time: 1000, logicalTime: 5, id: id)
        
        #expect(ts1 == ts2)
        #expect(!(ts1 < ts2))
        #expect(!(ts2 < ts1))
    }
    
    @Test("Timestamp hashing")
    func timestampHashing() {
        let id = UUID()
        let ts1 = Timestamp(time: 1000, logicalTime: 5, id: id)
        let ts2 = Timestamp(time: 1000, logicalTime: 5, id: id)
        
        #expect(ts1.hashValue == ts2.hashValue)
        
        let ts3 = Timestamp(time: 2000, logicalTime: 5, id: id)
        #expect(ts1.hashValue != ts3.hashValue)
    }
    
    @Test("Timestamp string description")
    func timestampStringDescription() {
        let id = UUID()
        let timestamp = Timestamp(time: 1000, logicalTime: 5, id: id)
        let description = timestamp.description
        
        #expect(description.contains("1000"))
        #expect(description.contains("5"))
        #expect(description.contains("Timestamp"))
    }
    
    @Test("Timestamp JSON encoding and decoding")
    func timestampCodable() throws {
        let id = UUID()
        let originalTimestamp = Timestamp(time: 1000, logicalTime: 5, id: id)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalTimestamp)
        
        let decoder = JSONDecoder()
        let decodedTimestamp = try decoder.decode(Timestamp.self, from: data)
        
        #expect(decodedTimestamp == originalTimestamp)
        #expect(decodedTimestamp.time == originalTimestamp.time)
        #expect(decodedTimestamp.logicalTime == originalTimestamp.logicalTime)
        #expect(decodedTimestamp.id == originalTimestamp.id)
    }
    
    @Test("Timestamp array sorting")
    func timestampArraySorting() {
        let id1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let id2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        
        let timestamps = [
            Timestamp(time: 3000, logicalTime: 0, id: id1),
            Timestamp(time: 1000, logicalTime: 5, id: id2),
            Timestamp(time: 1000, logicalTime: 3, id: id1),
            Timestamp(time: 2000, logicalTime: 0, id: id2)
        ]
        
        let sorted = timestamps.sorted()
        
        #expect(sorted[0].time == 1000 && sorted[0].logicalTime == 3)
        #expect(sorted[1].time == 1000 && sorted[1].logicalTime == 5)
        #expect(sorted[2].time == 2000 && sorted[2].logicalTime == 0)
        #expect(sorted[3].time == 3000 && sorted[3].logicalTime == 0)
    }
}