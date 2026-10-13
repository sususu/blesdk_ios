import AVFoundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Video→GIF via HaWoFit's vendored **FFmpeg 2.8** (`ffmpeg_main`), matching
/// `HWImageresizerViewController.convertVideoToGif:startTime:endTime:`.
///
/// Exact HaWoFit command template:
/// `ffmpeg -ss %d -i %@ -t %d -b:v 1M -g:v 20 -r 12 -fs 1MB -vf scale=W:H out.gif`
enum StudioVideoToGif {
    struct Options {
        var width: Int
        var height: Int
        /// Applied to first-frame preview only (HaWoFit rounds via JP crop, not ffmpeg).
        var cornerRadius: CGFloat
        var maxDuration: Int = 5
        var minDuration: Double = 2
        var startTime: Int = 0
        var endTime: Int = 5
        /// HaWoFit watchface GIF uses `-r 12`; AI path uses 8.
        var fps: Int = 12
    }

    enum Failure: LocalizedError {
        case cannotRead
        case tooShort
        case encodeFailed(String)
        var errorDescription: String? {
            switch self {
            case .cannotRead: return "Cannot read video"
            case .tooShort: return "Video too short"
            case .encodeFailed(let m): return m
            }
        }
    }

    /// HaWoFit: Documents/gif/{uuid}.gif
    static func convert(videoURL: URL, options: Options) throws -> (gifURL: URL, firstFrame: UIImage) {
        let asset = AVURLAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration.isFinite, duration > 0 else { throw Failure.cannotRead }
        // HaWoFit validateVideoDuration: >= minDuration - 0.5
        guard duration + 0.5 >= options.minDuration else { throw Failure.tooShort }

        var start = max(0, options.startTime)
        var end = max(start + 1, options.endTime)
        if Double(end) > duration { end = Int(duration.rounded(.down)) }
        if end <= start { end = min(Int(duration.rounded(.down)), start + options.maxDuration) }
        let clip = max(1, min(end - start, options.maxDuration))

        let out = try gifOutputURL()
        try? FileManager.default.removeItem(at: out)

        // Same argv HaWoFit builds (split by space), including leading "ffmpeg".
        // Paths are separate args so spaces stay intact.
        let args: [String] = [
            "ffmpeg",
            "-ss", "\(start)",
            "-i", videoURL.path,
            "-t", "\(clip)",
            "-b:v", "1M",
            "-g:v", "20",
            "-r", "\(options.fps)",
            "-fs", "1MB",
            "-vf", "scale=\(options.width):\(options.height)",
            out.path,
        ]

        let code = HaWoFFmpegBridge.run(withArguments: args)
        guard code == 0 else {
            throw Failure.encodeFailed("ffmpeg_main returned \(code)")
        }
        guard FileManager.default.fileExists(atPath: out.path) else {
            throw Failure.encodeFailed("GIF not written")
        }

        let first = firstFrame(ofGif: out)
            ?? placeholder(width: options.width, height: options.height, corner: options.cornerRadius)
        let rounded: UIImage
        if options.cornerRadius > 0,
           let masked = WatchfaceImageUtils.scaledRoundedBitmap(
            first,
            size: CGSize(width: options.width, height: options.height),
            cornerRadius: options.cornerRadius
           ) {
            rounded = masked
        } else {
            rounded = first
        }
        return (out, rounded)
    }

    private static func gifOutputURL() throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = docs.appendingPathComponent("gif", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(UUID().uuidString).gif")
    }

    private static func firstFrame(ofGif url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return UIImage(cgImage: cg)
    }

    private static func placeholder(width: Int, height: Int, corner: CGFloat) -> UIImage {
        let size = CGSize(width: width, height: height)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.black.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: corner).fill()
        }
    }
}
