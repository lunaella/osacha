// The chatter of a little thermal till printer, played in step with the
// receipt feeding out. It's synthesised here rather than shipped as a file:
// a stepper motor's fast ticks, its whine, and the rasp of paper, shaped
// into one short burst that plays for every line the receipt advances.

import AVFoundation

@MainActor
final class ReceiptPrinterSound {
    static let shared = ReceiptPrinterSound()

    private var player: AVAudioPlayer?

    private init() {}

    /// Builds the sound ahead of time so the first line isn't late.
    func prepare() {
        guard player == nil else { return }
        // Ambient: quiet when the phone is on silent, and mixes with music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        player = try? AVAudioPlayer(data: Self.burst(), fileTypeHint: AVFileType.wav.rawValue)
        player?.volume = 0.55
        player?.prepareToPlay()
    }

    /// One line of printing.
    func feedLine() {
        prepare()
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    // MARK: - Synthesis

    private static let sampleRate = 44_100.0

    /// About a tenth of a second of printing, as 16-bit mono WAV data.
    private static func burst() -> Data {
        let duration = 0.12
        let count = Int(duration * sampleRate)
        var samples = [Double](repeating: 0, count: count)

        // A fixed seed, so the printer sounds the same every time.
        var seed: UInt32 = 0x5EED
        func noise() -> Double {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            return Double(seed >> 8) / Double(1 << 24) * 2 - 1
        }

        let tickRate = 540.0      // stepper steps per second
        let tickPitch = 2_300.0   // the bright click of each step
        let whine = 270.0         // the motor underneath
        var rasp = 0.0            // paper noise, softened

        for i in 0..<count {
            let t = Double(i) / sampleRate

            let sinceTick = t.truncatingRemainder(dividingBy: 1 / tickRate)
            let tick = sin(2 * .pi * tickPitch * sinceTick) * exp(-sinceTick * 1_100)

            let motor = sin(2 * .pi * whine * t) + 0.35 * sin(2 * .pi * whine * 3 * t)

            rasp += 0.3 * (noise() - rasp)

            // Quick in, quick out, like the motor starting and stopping.
            let attack = min(1, t / 0.004)
            let release = min(1, (duration - t) / 0.025)
            let envelope = attack * max(0, release)

            samples[i] = envelope * (0.55 * tick + 0.12 * motor + 0.35 * rasp)
        }

        let peak = samples.map(abs).max() ?? 1
        let pcm = samples.map { Int16(($0 / peak * 0.8 * Double(Int16.max)).rounded()) }
        return wav(pcm)
    }

    private static func wav(_ pcm: [Int16]) -> Data {
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(pcm.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1))                    // PCM
        append(UInt16(1))                    // mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate) * 2)       // bytes per second
        append(UInt16(2))                    // bytes per frame
        append(UInt16(16))                   // bits per sample
        data.append(contentsOf: Array("data".utf8)); append(byteCount)
        pcm.forEach { append($0) }
        return data
    }
}
