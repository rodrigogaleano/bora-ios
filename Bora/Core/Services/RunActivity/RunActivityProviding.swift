import Foundation

/// Owns the Live Activity of a run: one activity, from the first block to the finish.
protocol RunActivityProviding {
    func start(planTitle: String, state: RunActivityAttributes.ContentState)
    func update(_ state: RunActivityAttributes.ContentState)
    func end(_ state: RunActivityAttributes.ContentState)
}
