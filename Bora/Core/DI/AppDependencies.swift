import Foundation

struct AppDependencies {
    let clock: ClockProviding
    let locationProvider: LocationProviding

    static let live = AppDependencies(clock: SystemClock(), locationProvider: SystemLocationProvider())

    static let preview = AppDependencies(clock: SystemClock(), locationProvider: PreviewLocationProvider())
}
