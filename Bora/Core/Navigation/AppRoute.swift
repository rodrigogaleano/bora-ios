enum AppRoute: Hashable {
    case summary(SessionPlan)
    case countdown(SessionPlan, PlannedRoute?)
    case execution(SessionPlan, PlannedRoute?)
    case results(SessionMetrics)
}
