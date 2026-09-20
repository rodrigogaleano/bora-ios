import Foundation

struct AppDependencies {
    let clock: ClockProviding
    let locationProvider: LocationProviding
    let settingsStore: RunSettingsStoring
    let cuePlayer: RunCueProviding
    let runActivity: RunActivityProviding

    static let live = AppDependencies(
        clock: SystemClock(),
        locationProvider: SystemLocationProvider(),
        settingsStore: UserDefaultsRunSettingsStore(),
        cuePlayer: SystemRunCuePlayer(),
        runActivity: SystemRunActivityController()
    )

    static let preview = AppDependencies(
        clock: SystemClock(),
        locationProvider: PreviewLocationProvider(),
        settingsStore: PreviewRunSettingsStore(),
        cuePlayer: PreviewRunCuePlayer(),
        runActivity: PreviewRunActivityController()
    )
}
