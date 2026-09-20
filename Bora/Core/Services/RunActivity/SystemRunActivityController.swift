import ActivityKit
import Foundation

final class SystemRunActivityController: RunActivityProviding {
    /// The finished run lingers on the lock screen long enough to be read, then clears
    /// itself — the detail lives on the Results screen.
    private static let dismissalDelay: TimeInterval = 120

    private var activity: Activity<RunActivityAttributes>?

    func start(planTitle: String, state: RunActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        activity = try? Activity.request(
            attributes: RunActivityAttributes(planTitle: planTitle),
            content: content(for: state),
            pushType: nil
        )
    }

    func update(_ state: RunActivityAttributes.ContentState) {
        guard let activity else { return }
        let content = content(for: state)
        Task { await activity.update(content) }
    }

    func end(_ state: RunActivityAttributes.ContentState) {
        guard let activity else { return }
        self.activity = nil
        let content = content(for: state)
        Task {
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(Self.dismissalDelay)))
        }
    }

    private func content(for state: RunActivityAttributes.ContentState)
        -> ActivityContent<RunActivityAttributes.ContentState> {
        ActivityContent(state: state, staleDate: nil)
    }
}
