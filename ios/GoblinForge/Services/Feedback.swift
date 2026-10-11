import AVFoundation
import UIKit

/// 敲击、交付、换装的声音与触感。正式音效 `sfx_hammer_*`（A0）到位前用程序合成的短促金属声占位：
/// 声音与触感只服务于时点，不阻塞输入（PRD 8.7、美术规范“敲击音效和触感必须可辨”）。
@MainActor
final class Feedback {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    private let tone = ToneSynth()

    func strike(heavy isHeavy: Bool) {
        (isHeavy ? heavy : rigid).impactOccurred()
        tone.ping(frequency: isHeavy ? 520 : 880, duration: isHeavy ? 0.22 : 0.12)
    }

    func deliver() {
        notification.notificationOccurred(.success)
        tone.ping(frequency: 660, duration: 0.3)
    }

    func swap() { light.impactOccurred() }
    func select() { selection.selectionChanged() }
    func reject() { notification.notificationOccurred(.warning) }
    func success() { notification.notificationOccurred(.success) }
}

/// 占位音效：几个泛音叠加并指数衰减的“叮”。ambient 会话：遵守静音开关、与其他音频混合。
/// 资源 ID `sfx_hammer_strike` / `sfx_hammer_form` / `sfx_deliver`（占位，不能作为最终资产验收）。
@MainActor
final class ToneSynth {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var format: AVAudioFormat?
    private var started = false

    func ping(frequency: Double, duration: Double) {
        guard prepare(), let format, let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                                                     frameCapacity: AVAudioFrameCount(format.sampleRate * duration)) else { return }
        buffer.frameLength = buffer.frameCapacity
        let rate = format.sampleRate
        let partials: [(Double, Double)] = [(1.0, 0.55), (2.76, 0.25), (5.4, 0.12)]
        if let channel = buffer.floatChannelData?[0] {
            for i in 0..<Int(buffer.frameLength) {
                let t = Double(i) / rate
                let envelope = exp(-t * 18) * min(1, t * 400)
                var sample = 0.0
                for (ratio, amp) in partials { sample += amp * sin(2 * .pi * frequency * ratio * t) }
                channel[i] = Float(sample * envelope * 0.35)
            }
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    private func prepare() -> Bool {
        if started { return true }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        self.format = format
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            started = true
        } catch {
            started = false
        }
        return started
    }
}
