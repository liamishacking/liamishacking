import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {

    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupAudioSession()
        setupAndPlayVideo()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session set up successfully")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func setupAndPlayVideo() {
        guard let videoPath = Bundle.main.path(forResource: "video", ofType: "mp4") else {
            print("Error: video.mp4 not found in bundle")
            exitApp()
            return
        }

        let videoURL = URL(fileURLWithPath: videoPath)
        let playerItem = AVPlayerItem(url: videoURL)

        player = AVPlayer(playerItem: playerItem)
        player?.volume = 1.0
        player?.isMuted = false

        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = false
        playerViewController?.videoGravity = .resizeAspectFill

        if let playerVC = playerViewController {
            addChild(playerVC)
            playerVC.view.frame = view.bounds
            playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )

        playerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new],
            context: nil
        )

        player?.play()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == #keyPath(AVPlayerItem.status) else { return }

        let statusValue = change?[.newKey] as? NSNumber
        let status = AVPlayerItem.Status(rawValue: statusValue?.intValue ?? -1) ?? .unknown

        switch status {
        case .readyToPlay:
            let audioTrackCount = player?.currentItem?.tracks.filter {
                $0.assetTrack?.mediaType == .audio
            }.count ?? 0
            print("Player ready - audio tracks found: \(audioTrackCount)")
            player?.volume = 1.0
            player?.isMuted = false
            player?.play()

        case .failed:
            let errorMessage = player?.currentItem?.error?.localizedDescription ?? "unknown"
            print("Player failed: \(errorMessage)")

        case .unknown:
            print("Player status unknown")

        @unknown default:
            break
        }
    }

    @objc private func videoDidFinishPlaying() {
        print("Video finished. Closing app...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.exitApp()
        }
    }

    private func exitApp() {
        player?.pause()
        try? AVAudioSession.sharedInstance().setActive(false)
        NotificationCenter.default.removeObserver(self)
        player?.currentItem?.removeObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status)
        )
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerViewController?.view.frame = view.bounds
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
