import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {

    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupAndPlayVideo()
    }

    private func setupAndPlayVideo() {
        guard let videoPath = Bundle.main.path(forResource: "video", ofType: "mp4") else {
            print("Error: video.mp4 not found in bundle")
            exitApp()
            return
        }

        let videoURL = URL(fileURLWithPath: videoPath)

        player = AVPlayer(url: videoURL)

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

        player?.play()
    }

    @objc private func videoDidFinishPlaying() {
        print("Video finished. Closing app...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.exitApp()
        }
    }

    private func exitApp() {
        player?.pause()
        NotificationCenter.default.removeObserver(self)
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
