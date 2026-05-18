import UIKit

/// Helpers for shrinking avatar images before they hit Core Data.
/// Keeps the binary small enough to sync via CloudKit later without bloat.
enum AvatarImage {
    /// 256pt max dimension at JPEG 0.8 keeps avatars under ~30 KB.
    static let maxDimension: CGFloat = 256
    static let jpegQuality: CGFloat = 0.8

    static func processed(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = image.aspectFitted(to: maxDimension)
        return resized.jpegData(compressionQuality: jpegQuality)
    }
}

private extension UIImage {
    func aspectFitted(to maxDim: CGFloat) -> UIImage {
        let aspect = size.width / size.height
        let target: CGSize
        if aspect >= 1 {
            target = CGSize(width: maxDim, height: maxDim / aspect)
        } else {
            target = CGSize(width: maxDim * aspect, height: maxDim)
        }
        if target.width >= size.width && target.height >= size.height {
            return self
        }
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
