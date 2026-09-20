import ActivityKit
import SwiftUI
import WidgetKit

struct RunActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            LockScreenView(planTitle: context.attributes.planTitle, state: context.state)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.phaseTitle)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RunActivityTimer(state: context.state)
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MetricsRow(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "figure.run")
            } compactTrailing: {
                RunActivityTimer(state: context.state)
                    .font(.caption.monospacedDigit())
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "figure.run")
            }
        }
    }
}

/// The timer is a `Text(timerInterval:)` so the system renders every tick on its own —
/// the app never wakes up just to move a clock. Blocks with no end (distance-gated, or an
/// open-ended goal) count up instead of down.
private struct RunActivityTimer: View {
    let state: RunActivityAttributes.ContentState

    var body: some View {
        if let endsAt = state.phaseEndsAt {
            Text(timerInterval: state.phaseStartedAt...endsAt, pauseTime: state.pausedAt, countsDown: true)
        } else {
            Text(
                timerInterval: state.phaseStartedAt...Date.distantFuture,
                pauseTime: state.pausedAt,
                countsDown: false
            )
        }
    }
}

/// Symbols instead of labels: every string here would otherwise need its own catalog in
/// the extension, and the numbers read fine on their own.
private struct MetricsRow: View {
    let state: RunActivityAttributes.ContentState

    var body: some View {
        HStack {
            Label(
                RunFormatting.distance(meters: state.distanceMeters),
                systemImage: "point.topleft.down.to.point.bottomright.curvepath"
            )
            Spacer()
            Label(RunFormatting.pace(secondsPerKm: state.paceSecondsPerKm), systemImage: "speedometer")
        }
        .font(.subheadline.monospacedDigit())
    }
}

private struct LockScreenView: View {
    let planTitle: String
    let state: RunActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(state.phaseTitle)
                    .font(.headline)
                Spacer()
                Text("\(state.phaseNumber)/\(state.phaseCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline) {
                RunActivityTimer(state: state)
                    .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                Spacer()
                Text(planTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            MetricsRow(state: state)

            if let upcoming = state.upcomingPhaseTitle {
                Label(upcoming, systemImage: "arrow.right.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
