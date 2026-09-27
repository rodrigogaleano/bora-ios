import Testing
@testable import Bora

struct DistanceUnitTests {
    @Test func kilometersConvertToAndFromMeters() {
        #expect(DistanceUnit.kilometers.value(fromMeters: 1_500) == 1.5)
        #expect(DistanceUnit.kilometers.meters(from: 1.5) == 1_500)
    }

    @Test func metersStayUnchanged() {
        #expect(DistanceUnit.meters.value(fromMeters: 400) == 400)
        #expect(DistanceUnit.meters.meters(from: 400) == 400)
    }
}
