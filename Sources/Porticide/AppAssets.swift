import AppKit

@MainActor
enum AppAssets {
    /// The knife logo as a template image, so it follows the menu bar and popover tint.
    static let logo: NSImage? = {
        guard let url = resourceBundle.url(forResource: "knife", withExtension: "svg"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        return image
    }()

    /// SwiftPM places resources in `Porticide_Porticide.bundle`. In a packaged `.app` that bundle
    /// lives in `Contents/Resources`, where `Bundle.module` does not look, so check there first.
    private static let resourceBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Porticide_Porticide", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return Bundle.module
    }()
}
