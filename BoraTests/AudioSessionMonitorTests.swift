import AVFoundation
import Testing
@testable import Bora

struct AudioSessionMonitorTests {
    @Test func aRunningInterruptionDoesNotRecoverYet() {
        var monitor = AudioSessionMonitor()

        #expect(monitor.handle(.interruptionBegan) == .none)
        #expect(monitor.isInterrupted)
    }

    @Test func theEndOfAnInterruptionAlwaysRecovers() {
        var monitor = AudioSessionMonitor()
        _ = monitor.handle(.interruptionBegan)

        #expect(monitor.handle(.interruptionEnded) == .recover)
        #expect(!monitor.isInterrupted)
    }

    @Test func headphonesComingOrGoingRecovers() {
        var monitor = AudioSessionMonitor()

        #expect(monitor.handle(.routeChanged(.oldDeviceUnavailable)) == .recover)
        #expect(monitor.handle(.routeChanged(.newDeviceAvailable)) == .recover)
        #expect(monitor.handle(.routeChanged(.override)) == .recover)
    }

    @Test func irrelevantRouteChangesAreIgnored() {
        var monitor = AudioSessionMonitor()

        #expect(monitor.handle(.routeChanged(.categoryChange)) == .none)
        #expect(monitor.handle(.routeChanged(.wakeFromSleep)) == .none)
    }

    @Test func anEngineConfigurationChangeRecovers() {
        var monitor = AudioSessionMonitor()

        #expect(monitor.handle(.engineConfigurationChanged) == .recover)
    }

    @Test func routeChangesDuringACallWaitForTheInterruptionToEnd() {
        var monitor = AudioSessionMonitor()
        _ = monitor.handle(.interruptionBegan)

        #expect(monitor.handle(.routeChanged(.oldDeviceUnavailable)) == .none)
        #expect(monitor.handle(.engineConfigurationChanged) == .none)
        #expect(monitor.handle(.interruptionEnded) == .recover)
    }

    @Test func aMediaServicesResetRebuildsEvenMidInterruption() {
        var monitor = AudioSessionMonitor()
        _ = monitor.handle(.interruptionBegan)

        #expect(monitor.handle(.mediaServicesReset) == .rebuild)
        #expect(!monitor.isInterrupted)
    }
}
