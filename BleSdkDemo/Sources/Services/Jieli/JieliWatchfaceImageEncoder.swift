import UIKit
import JLBmpConvertKit

enum JieliWatchfaceImageEncoder {
    static func convert(_ imageData: Data) -> Data? {
        let option = JLBmpConvertOption()
        option.convertType = .type707N_ARGB
        option.pixelformat = ._Auto
        return JLBmpConvert.convert(option, imageData: imageData).outFileData
    }

    static func renderedImage(_ image: UIImage,
                              size: CGSize,
                              cornerRadius: CGFloat) throws -> UIImage {
        guard image.size.width > 0, image.size.height > 0,
              size.width > 0, size.height > 0 else {
            throw SdkError(code: -1, message: L10n.tr("wf_err_size"))
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: max(0, cornerRadius)
            ).addClip()

            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: CGRect(
                x: (size.width - drawSize.width) / 2,
                y: (size.height - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
        }
    }

    static func encode(_ image: UIImage,
                       size: CGSize,
                       cornerRadius: CGFloat) throws -> Data {
        let rendered = try renderedImage(image, size: size, cornerRadius: cornerRadius)
        guard let imageData = rendered.jpegData(compressionQuality: 1) else {
            throw SdkError(code: -1, message: "image encode failed")
        }

        guard let data = convert(imageData), !data.isEmpty else {
            throw SdkError(code: -1, message: "JL image convert failed")
        }
        return data
    }
}
