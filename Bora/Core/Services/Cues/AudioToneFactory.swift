import AVFoundation

/// Builds the PCM buffers the cue player schedules. Tones are synthesized instead of
/// shipped as assets so the repo stays free of audio binaries and the metronome can be
/// rebuilt at any BPM.
enum AudioToneFactory {
    static let sampleRate: Double = 44_100

    private static let envelopeSeconds: TimeInterval = 0.005

    static func makeFormat() -> AVAudioFormat? {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
    }

    /// A single sine burst, optionally padded with trailing silence up to `totalDuration`.
    /// The padding is what turns one click into an exact metronome beat.
    static func makeTone(
        format: AVAudioFormat,
        frequency: Double,
        duration: TimeInterval,
        totalDuration: TimeInterval? = nil,
        amplitude: Float = 0.6
    ) -> AVAudioPCMBuffer? {
        makeSequence(
            format: format,
            frequency: frequency,
            duration: duration,
            count: 1,
            interval: totalDuration ?? duration,
            amplitude: amplitude
        )
    }

    /// `count` evenly spaced bursts in one buffer — scheduling a single buffer keeps the
    /// spacing sample-accurate instead of relying on timers between play calls.
    static func makeSequence(
        format: AVAudioFormat,
        frequency: Double,
        duration: TimeInterval,
        count: Int,
        interval: TimeInterval,
        amplitude: Float = 0.6
    ) -> AVAudioPCMBuffer? {
        guard count > 0, duration > 0, interval >= duration else { return nil }
        let intervalFrames = Int(interval * format.sampleRate)
        let toneFrames = Int(duration * format.sampleRate)
        let totalFrames = AVAudioFrameCount(intervalFrames * count)
        guard
            totalFrames > 0,
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
            let channel = buffer.floatChannelData?[0]
        else {
            return nil
        }
        buffer.frameLength = totalFrames

        let envelopeFrames = max(1, Int(envelopeSeconds * format.sampleRate))
        for frame in 0..<Int(totalFrames) {
            let frameInBeat = frame % intervalFrames
            guard frameInBeat < toneFrames else {
                channel[frame] = 0
                continue
            }
            // Fade the burst in and out; a hard cut at either edge pops.
            let envelope = min(
                Float(frameInBeat) / Float(envelopeFrames),
                Float(toneFrames - frameInBeat) / Float(envelopeFrames),
                1
            )
            let phase = 2 * Double.pi * frequency * Double(frameInBeat) / format.sampleRate
            channel[frame] = Float(sin(phase)) * amplitude * max(0, envelope)
        }
        return buffer
    }
}
