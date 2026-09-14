import Foundation

struct AppDependencies {
    let clock: ClockProviding

    static let live = AppDependencies(clock: SystemClock())

    static let preview = AppDependencies(clock: SystemClock())
}
