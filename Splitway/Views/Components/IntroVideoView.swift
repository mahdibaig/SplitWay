import SwiftUI
import AVKit

/// Plays a clip exactly once, muted, with no controls, then holds on the
/// final frame. Built on `AVPlayerLayer` (not `AVPlayerViewController`) so
/// there is no scrubber or play button. A plain `AVPlayer` pauses at the end
/// by default and `AVPlayerLayer` keeps the last decoded frame on screen, so
/// the clip "ends and stays paused" with no extra work.
struct IntroVideoView: UIViewRepresentable {
    let url: URL
    var gravity: AVLayerVideoGravity = .resizeAspect

    func makeUIView(context: Context) -> IntroPlayerView {
        IntroPlayerView(url: url, gravity: gravity)
    }

    func updateUIView(_ uiView: IntroPlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: IntroPlayerView, coordinator: ()) {
        uiView.stop()
    }
}

final class IntroPlayerView: UIView {
    private let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    private var endObserver: NSObjectProtocol?

    init(url: URL, gravity: AVLayerVideoGravity) {
        super.init(frame: .zero)
        backgroundColor = .clear

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.isMuted = true
        // .pause is AVPlayer's default at end-of-item; being explicit so the
        // intent ("stop on the last frame") is obvious to the next reader.
        player.actionAtItemEnd = .pause

        playerLayer.player = player
        playerLayer.videoGravity = gravity
        layer.addSublayer(playerLayer)

        // Belt-and-suspenders: if anything nudges playback past the end,
        // re-pin to the final frame instead of showing black.
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player.pause()
        }

        player.play()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func stop() {
        player.pause()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}
