import Foundation

struct KilometerSplitRecorder {
    private(set) var completed: [SessionMetrics.KilometerSplit] = []
    private var lastMarkElapsed: TimeInterval = 0

    mutating func record(totalMeters: Double, elapsed: TimeInterval) {
        let crossed = Int(totalMeters / 1000)
        guard crossed > completed.count else { return }
        let newKilometers = crossed - completed.count
        let duration = (elapsed - lastMarkElapsed) / Double(newKilometers)
        for _ in 0..<newKilometers {
            completed.append(SessionMetrics.KilometerSplit(distanceMeters: 1000, duration: duration))
        }
        lastMarkElapsed = elapsed
    }

    func splits(totalMeters: Double, elapsed: TimeInterval) -> [SessionMetrics.KilometerSplit] {
        let remainder = totalMeters - Double(completed.count) * 1000
        guard remainder >= PhasePacer.minimumDistanceMeters else { return completed }
        return completed + [
            SessionMetrics.KilometerSplit(distanceMeters: remainder, duration: elapsed - lastMarkElapsed)
        ]
    }
}
