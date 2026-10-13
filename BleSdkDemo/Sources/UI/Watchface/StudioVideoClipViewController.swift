import AVFoundation
import ImageIO
import UIKit

/// HaWoFit-style Video→GIF clip page:
/// pick range (min 2s / max 5s) → ffmpeg convert → preview → Use.
///
/// Mirrors `HWImageresizerViewController` + `HwVideoClipPreview` flow without
/// JPImageresizer / SAVideoRangeSlider (HaWoFit headers partially DRM-locked).
final class StudioVideoClipViewController: UIViewController {
    var videoURL: URL!
    var dialWidth: Int = 466
    var dialHeight: Int = 466
    var dialCorner: CGFloat = 233
    var maxDuration: Int = 5
    var minDuration: Double = 2
    var onCompleted: ((URL, UIImage) -> Void)?

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private let previewHost = UIView()
    private let dialView = UIView()
    private let tipsLabel = UILabel()
    private let startSlider = UISlider()
    private let lengthSlider = UISlider()
    private let rangeLabel = UILabel()
    private let convertButton = UIHelpers.makeButton("", primary: true)
    private let busy = UIActivityIndicatorView(style: .large)
    private var videoDuration: Double = 0
    private var gifPreview: UIImageView?
    private var pendingGif: (URL, UIImage)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = L10n.tr("wfs_video")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel)
        )

        let asset = AVURLAsset(url: videoURL)
        videoDuration = CMTimeGetSeconds(asset.duration)
        if !(videoDuration.isFinite && videoDuration + 0.5 >= minDuration) {
            // Defer dismiss after presentation.
            DispatchQueue.main.async { [weak self] in
                self?.failAndPop(L10n.tr("wfs_video_too_short"))
            }
            return
        }

        setupChrome()
        setupPlayer()
        syncRangeLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutDial()
        playerLayer?.frame = dialView.bounds
    }

    private func setupChrome() {
        tipsLabel.textColor = UIColor(white: 0.7, alpha: 1)
        tipsLabel.font = .systemFont(ofSize: 14)
        tipsLabel.textAlignment = .center
        tipsLabel.numberOfLines = 0
        tipsLabel.text = String(format: L10n.tr("wfs_video_trim_tip"), maxDuration)

        rangeLabel.textColor = .white
        rangeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        rangeLabel.textAlignment = .center

        startSlider.minimumValue = 0
        startSlider.maximumValue = Float(max(0, videoDuration - minDuration))
        startSlider.value = 0
        startSlider.addTarget(self, action: #selector(rangeChanged), for: .valueChanged)

        lengthSlider.minimumValue = Float(minDuration)
        lengthSlider.maximumValue = Float(maxDuration)
        lengthSlider.value = Float(min(Double(maxDuration), videoDuration, max(minDuration, 3)))
        lengthSlider.addTarget(self, action: #selector(rangeChanged), for: .valueChanged)

        convertButton.setTitle(L10n.tr("wfs_video_make_gif"), for: .normal)
        convertButton.addTarget(self, action: #selector(makeGif), for: .touchUpInside)

        busy.hidesWhenStopped = true
        busy.color = .white

        dialView.backgroundColor = .darkGray
        dialView.clipsToBounds = true
        previewHost.addSubview(dialView)

        let stack = UIStackView(arrangedSubviews: [
            previewHost, tipsLabel, rangeLabel, startSlider, lengthSlider, convertButton,
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        previewHost.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.addSubview(busy)
        busy.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewHost.heightAnchor.constraint(equalToConstant: 300),
            busy.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            busy.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func layoutDial() {
        let maxSide: CGFloat = 280
        let scale = maxSide / CGFloat(max(dialWidth, dialHeight))
        let w = CGFloat(dialWidth) * scale
        let h = CGFloat(dialHeight) * scale
        dialView.bounds = CGRect(x: 0, y: 0, width: w, height: h)
        dialView.center = CGPoint(x: previewHost.bounds.midX, y: previewHost.bounds.midY)
        dialView.layer.cornerRadius = dialCorner * scale
    }

    private func setupPlayer() {
        let player = AVPlayer(url: videoURL)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        dialView.layer.addSublayer(layer)
        self.player = player
        self.playerLayer = layer
        player.play()
        NotificationCenter.default.addObserver(
            self, selector: #selector(loopPlayer),
            name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem
        )
    }

    @objc private func loopPlayer() {
        let start = Double(startSlider.value)
        player?.seek(to: CMTime(seconds: start, preferredTimescale: 600))
        player?.play()
    }

    @objc private func rangeChanged() {
        let start = Double(startSlider.value)
        var len = Double(lengthSlider.value)
        if start + len > videoDuration {
            len = max(minDuration, videoDuration - start)
            lengthSlider.value = Float(len)
        }
        player?.seek(to: CMTime(seconds: start, preferredTimescale: 600))
        syncRangeLabel()
    }

    private func syncRangeLabel() {
        let start = Int(startSlider.value.rounded())
        let len = Int(lengthSlider.value.rounded())
        rangeLabel.text = L10n.tr("wfs_video_range", start, start + len)
    }

    @objc private func makeGif() {
        if let pending = pendingGif {
            onCompleted?(pending.0, pending.1)
            navigationController?.popViewController(animated: true)
            return
        }
        busy.startAnimating()
        convertButton.isEnabled = false
        player?.pause()
        let start = Int(startSlider.value.rounded())
        let end = start + Int(lengthSlider.value.rounded())
        let url = videoURL!
        let w = dialWidth, h = dialHeight, corner = dialCorner
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let result = try StudioVideoToGif.convert(
                    videoURL: url,
                    options: .init(
                        width: w, height: h, cornerRadius: corner,
                        maxDuration: self?.maxDuration ?? 5,
                        minDuration: self?.minDuration ?? 2,
                        startTime: start, endTime: end
                    )
                )
                DispatchQueue.main.async {
                    self?.showGifPreview(result.gifURL, first: result.firstFrame)
                }
            } catch StudioVideoToGif.Failure.tooShort {
                DispatchQueue.main.async {
                    self?.busy.stopAnimating()
                    self?.convertButton.isEnabled = true
                    self?.failAndPop(L10n.tr("wfs_video_too_short"))
                }
            } catch {
                DispatchQueue.main.async {
                    self?.busy.stopAnimating()
                    self?.convertButton.isEnabled = true
                    self?.statusAlert(L10n.tr("wfs_gif_fail"))
                }
            }
        }
    }

    private func showGifPreview(_ gifURL: URL, first: UIImage) {
        busy.stopAnimating()
        pendingGif = (gifURL, first)
        convertButton.setTitle(L10n.tr("wfs_video_use_gif"), for: .normal)
        convertButton.isEnabled = true
        player?.pause()
        playerLayer?.isHidden = true
        let iv = UIImageView(image: first)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.frame = dialView.bounds
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Animate GIF if possible
        if let data = try? Data(contentsOf: gifURL),
           let anim = UIImage.animatedImage(withAnimatedGIFData: data) {
            iv.image = anim
        }
        dialView.addSubview(iv)
        gifPreview = iv
        tipsLabel.text = L10n.tr("wfs_gif_ready")
    }

    @objc private func cancel() {
        navigationController?.popViewController(animated: true)
    }

    private func failAndPop(_ message: String) {
        statusAlert(message) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func statusAlert(_ message: String, then: (() -> Void)? = nil) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in then?() })
        present(a, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
    }
}

private extension UIImage {
    /// Minimal animated-GIF loader for clip preview (HaWoFit uses SDWebImage).
    static func animatedImage(withAnimatedGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return nil }
        var frames: [UIImage] = []
        var duration: Double = 0
        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.08
            duration += max(0.02, delay)
            frames.append(UIImage(cgImage: cg))
        }
        guard !frames.isEmpty else { return nil }
        return UIImage.animatedImage(with: frames, duration: duration)
    }
}
