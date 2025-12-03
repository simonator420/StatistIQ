import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        // Create banner of standard banner size (320x50 on phones)
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID

        // Root view controller is required
        if let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController {
            banner.rootViewController = rootVC
        }

        // Load an ad
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // nothing to update
    }
}
