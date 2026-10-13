import ImageIO
import UIKit

/// Lightweight animated-GIF loader (HaWoFit uses SDWebImage for the same job).
enum AnimatedGIF {
    /// Returns an animated `UIImage` when the file has multiple frames; otherwise a still image.
    static func image(contentsOf url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return image(data: data)
    }

    static func image(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return UIImage(data: data) }
        if count == 1 {
            guard let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return UIImage(data: data)
            }
            return UIImage(cgImage: cg)
        }

        var frames: [UIImage] = []
        var duration: Double = 0
        frames.reserveCapacity(count)
        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cg))
            duration += frameDelay(source: source, index: i)
        }
        guard !frames.isEmpty else { return UIImage(data: data) }
        // UIImage animatedImage requires duration > 0.
        return UIImage.animatedImage(with: frames, duration: max(duration, Double(frames.count) * 0.08))
    }

    private static func frameDelay(source: CGImageSource, index: Int) -> Double {
        let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gif = props?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
            ?? 0.1
        // Browsers / SDWebImage clamp very small delays to ~10ms→100ms.
        if delay < 0.011 { return 0.1 }
        return delay
    }
}
