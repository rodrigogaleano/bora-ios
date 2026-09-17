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

        let viewModel = makeViewModel(store: PreviewRunSettingsStore(settings: stored))

        #expect(!viewModel.isBeepEnabled)
        #expect(viewModel.isMetronomeEnabled)
        #expect(viewModel.metronomeBPM == 160)
    }

    @Test func togglingPersistsImmediately() {
        let store = PreviewRunSettingsStore()
        let viewModel = makeViewModel(store: store)

        viewModel.isVoiceCueEnabled = false

        #expect(!store.load().isVoiceCueEnabled)
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
