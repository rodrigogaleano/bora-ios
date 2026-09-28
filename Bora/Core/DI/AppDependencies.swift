import Foundation

struct AppDependencies {
    let clock: ClockProviding
    let locationProvider: LocationProviding
    let settingsStore: RunSettingsStoring
    let cuePlayer: RunCueProviding
    let runActivity: RunActivityProviding
    let routeSnapshotter: RouteSnapshotProviding

    static let live = AppDependencies(
        clock: SystemClock(),
        locationProvider: SystemLocationProvider(),
        settingsStore: UserDefaultsRunSettingsStore(),
        cuePlayer: SystemRunCuePlayer(),
        runActivity: SystemRunActivityController(),
        routeSnapshotter: MapKitRouteSnapshotter()
    )

    static let preview = AppDependencies(
        clock: SystemClock(),
        locationProvider: PreviewLocationProvider(),
        settingsStore: PreviewRunSettingsStore(),
        cuePlayer: PreviewRunCuePlayer(),
        runActivity: PreviewRunActivityController(),
        routeSnapshotter: PreviewRouteSnapshotter()
    )
}
