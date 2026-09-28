import Foundation

struct AppDependencies {
    let clock: ClockProviding
    let locationProvider: LocationProviding
    let settingsStore: RunSettingsStoring
    let lastWorkoutStore: LastWorkoutStoring
    let cuePlayer: RunCueProviding
    let runActivity: RunActivityProviding
    let routeSnapshotter: RouteSnapshotProviding

    static let live = AppDependencies(
        clock: SystemClock(),
        locationProvider: SystemLocationProvider(),
        settingsStore: UserDefaultsRunSettingsStore(),
        lastWorkoutStore: UserDefaultsLastWorkoutStore(),
        cuePlayer: SystemRunCuePlayer(),
        runActivity: SystemRunActivityController(),
        routeSnapshotter: MapKitRouteSnapshotter()
    )

    static let preview = AppDependencies(
        clock: SystemClock(),
        locationProvider: PreviewLocationProvider(),
        settingsStore: PreviewRunSettingsStore(),
        lastWorkoutStore: PreviewLastWorkoutStore(),
        cuePlayer: PreviewRunCuePlayer(),
        runActivity: PreviewRunActivityController(),
        routeSnapshotter: PreviewRouteSnapshotter()
    )
}
