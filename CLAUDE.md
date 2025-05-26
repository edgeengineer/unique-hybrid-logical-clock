1. Create a Cross Platform Swift 6.1 Library called `UniqueHybridLogicalClock` in this current directory. No need to create another directory.
2. Make it a port of the functionality from https://github.com/atolab/uhlc-rs 
3. Create comprehensive tests using Swift Testing and DO NOT INTRODUCE XCTest
4. The remote origin is git remote add origin git@github.com:edgeengineer/unique-hybrid-logical-clock.git
5. Create a README.md with a quickstart of installation and how to use it and say how it's a port of https://github.com/atolab/uhlc-rs 
6. Write comprehensive tests
7. Public methods should have a lot of DocC friendly examples
8. Use `FoundationEssentials` when possible with `#if canImport(FoundationEssentials)` for Linux uses