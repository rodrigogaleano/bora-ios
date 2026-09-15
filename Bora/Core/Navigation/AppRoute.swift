enum AppRoute: Hashable {
    case route(SessionPlan)
    case execution(SessionPlan, PlannedRoute)
    case results
}
