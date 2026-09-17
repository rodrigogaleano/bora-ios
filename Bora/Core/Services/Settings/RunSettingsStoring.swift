protocol RunSettingsStoring {
    func load() -> RunSettings
    func save(_ settings: RunSettings)
}
