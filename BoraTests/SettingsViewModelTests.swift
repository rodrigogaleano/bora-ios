import Testing
@testable import Bora

struct SettingsViewModelTests {
    private func makeViewModel(
        store: PreviewRunSettingsStore = PreviewRunSettingsStore(),
        cuePlayer: PreviewRunCuePlayer = PreviewRunCuePlayer(),
        onDone: @escaping () -> Void = {}
    ) -> SettingsViewModel {
        SettingsViewModel(store: store, cuePlayer: cuePlayer, onDone: onDone)
    }

    @Test func loadsStoredSettingsOnInit() {
        var stored = RunSettings()
        stored.isBeepEnabled = false
        stored.isMetronomeEnabled = true
        stored.metronomeBPM = 160
        stored.gpsAccuracy = .high
        stored.metronomeVolume = 0.2

        let viewModel = makeViewModel(store: PreviewRunSettingsStore(settings: stored))

        #expect(!viewModel.isBeepEnabled)
        #expect(viewModel.isMetronomeEnabled)
        #expect(viewModel.metronomeBPM == 160)
        #expect(viewModel.gpsAccuracy == .high)
        #expect(viewModel.metronomeVolume == 0.2)
    }

    @Test func togglingPersistsImmediately() {
        let store = PreviewRunSettingsStore()
        let viewModel = makeViewModel(store: store)

        viewModel.isVoiceCueEnabled = false

        #expect(!store.load().isVoiceCueEnabled)
    }

    @Test func changingGpsAccuracyPersistsImmediately() {
        let store = PreviewRunSettingsStore()
        let viewModel = makeViewModel(store: store)

        viewModel.gpsAccuracy = .economy

        #expect(store.load().gpsAccuracy == .economy)
    }

    @Test func bpmIsClampedToSupportedRange() {
        let store = PreviewRunSettingsStore()
        let viewModel = makeViewModel(store: store)

        viewModel.metronomeBPM = 400
        #expect(viewModel.metronomeBPM == RunSettings.bpmRange.upperBound)

        viewModel.metronomeBPM = 10
        #expect(viewModel.metronomeBPM == RunSettings.bpmRange.lowerBound)
        #expect(store.load().metronomeBPM == RunSettings.bpmRange.lowerBound)
    }

    @Test func metronomeVolumeIsClampedAndPersisted() {
        let store = PreviewRunSettingsStore()
        let viewModel = makeViewModel(store: store)

        viewModel.metronomeVolume = 5
        #expect(viewModel.metronomeVolume == RunSettings.metronomeVolumeRange.upperBound)

        viewModel.metronomeVolume = 0
        #expect(viewModel.metronomeVolume == RunSettings.metronomeVolumeRange.lowerBound)
        #expect(store.load().metronomeVolume == RunSettings.metronomeVolumeRange.lowerBound)
    }

    @Test func metronomeVolumeReachesThePlayerWhileItIsPlaying() {
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(cuePlayer: cuePlayer)
        viewModel.isMetronomeEnabled = true
        viewModel.testCues()

        viewModel.metronomeVolume = 0.1

        #expect(cuePlayer.metronomeVolume == 0.1)
    }

    @Test func testCuesPlaysThroughThePlayerHonoringMetronomeToggle() {
        let cuePlayer = PreviewRunCuePlayer()
        let viewModel = makeViewModel(cuePlayer: cuePlayer)
        viewModel.isMetronomeEnabled = true

        viewModel.testCues()

        #expect(cuePlayer.preparedSettings?.isMetronomeEnabled == true)
        #expect(cuePlayer.playedCues.count == 1)
        #expect(cuePlayer.isMetronomeRunning)
    }

    @Test func doneStopsAudioAndInvokesCallback() {
        let cuePlayer = PreviewRunCuePlayer()
        var didFinish = false
        let viewModel = makeViewModel(cuePlayer: cuePlayer, onDone: { didFinish = true })

        viewModel.testCues()
        viewModel.done()

        #expect(didFinish)
        #expect(cuePlayer.isTornDown)
        #expect(!cuePlayer.isMetronomeRunning)
    }
}
