import Foundation
import Testing
@testable import Bora

struct RunSpeechFormattingTests {
    private let locale = Locale(identifier: "en_US")

    @Test func paceSpeaksMinutesAndSeconds() {
        #expect(RunSpeechFormatting.pace(secondsPerKm: 342.4) == "pace 5 42")
    }

    @Test func shortDistanceIsSpokenInMeters() {
        #expect(RunSpeechFormatting.distance(meters: 283, locale: locale) == "280 meters")
    }

    @Test func longDistanceIsSpokenInKilometers() {
        #expect(RunSpeechFormatting.distance(meters: 1_234, locale: locale) == "1.2 kilometers")
    }

    @Test func durationIsSpokenInWords() {
        #expect(RunSpeechFormatting.duration(92, locale: locale) == "1 minute, 32 seconds")
        #expect(RunSpeechFormatting.duration(60, locale: locale) == "1 minute")
    }
}
