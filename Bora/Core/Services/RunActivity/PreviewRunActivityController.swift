import Foundation

final class PreviewRunActivityController: RunActivityProviding {
    func start(planTitle: String, state: RunActivityAttributes.ContentState) {}
    func update(_ state: RunActivityAttributes.ContentState) {}
    func end(_ state: RunActivityAttributes.ContentState) {}
}
