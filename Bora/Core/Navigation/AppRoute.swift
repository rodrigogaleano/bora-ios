enum AppRoute: Hashable {
    case route(SessionPlan)
    case countdown(SessionPlan, PlannedRoute)
    case execution(SessionPlan, PlannedRoute)
    case results(SessionMetrics)
}
