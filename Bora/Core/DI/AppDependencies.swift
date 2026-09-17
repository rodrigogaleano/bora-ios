import Foundation

struct AppDependencies {
    let clock: ClockProviding
    let locationProvider: LocationProviding
    let settingsStore: RunSettingsStoring
    let cuePlayer: RunCueProviding

    static let live = AppDependencies(
        clock: SystemClock(),
        locationProvider: SystemLocationProvider(),
        settingsStore: UserDefaultsRunSettingsStore(),
        cuePlayer: SystemRunCuePlayer()
    )

    static let preview = AppDependencies(
        clock: SystemClock(),
        locationProvider: PreviewLocationProvider(),
        settingsStore: PreviewRunSettingsStore(),
        cuePlayer: PreviewRunCuePlayer()
    )
}
