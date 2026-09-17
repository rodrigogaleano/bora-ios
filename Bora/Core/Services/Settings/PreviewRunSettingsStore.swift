final class PreviewRunSettingsStore: RunSettingsStoring {
    private(set) var settings: RunSettings

    init(settings: RunSettings = RunSettings()) {
        self.settings = settings
    }

    func load() -> RunSettings {
        settings
    }

    func save(_ settings: RunSettings) {
        self.settings = settings
    }
}
