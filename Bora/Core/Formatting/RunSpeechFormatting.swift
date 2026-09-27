import Foundation

enum RunSpeechFormatting {
    static func pace(secondsPerKm: Double) -> String {
        let totalSeconds = Int(secondsPerKm.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(localized: "pace \(minutes) \(seconds)")
    }

    static func duration(_ interval: TimeInterval, locale: Locale = .current) -> String {
        var calendar = Calendar.current
        calendar.locale = locale
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: max(1, interval.rounded())) ?? ""
    }

    static func distance(meters: Double, locale: Locale = .current) -> String {
        let rounded = (meters / 10).rounded() * 10
        if rounded < 1000 {
            return Measurement(value: rounded, unit: UnitLength.meters)
                .formatted(.measurement(width: .wide, usage: .asProvided).locale(locale))
        }
        let kilometers = (meters / 100).rounded() / 10
        let style = Measurement<UnitLength>.FormatStyle(
            width: .wide,
            locale: locale,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(0...1))
        )
        return Measurement(value: kilometers, unit: UnitLength.kilometers).formatted(style)
    }
}
