import Foundation
import Observation

@MainActor @Observable final class CheckInViewModel {
    var noise = 3
    var crowd = 3
    var wifi = 3
    var outlets = 3
    var rating = 0
    var price = ""
    var comment = ""
    var submitted = false
    var isBusy = false
    var error: String?
    var result: XPResult?

    var ratingError: String? { submitted ? Validators.rating(rating) : nil }
    var commentError: String? { Validators.comment(comment) }
    var priceError: String? { Validators.price(price) }
    var isValid: Bool { Validators.rating(rating) == nil && commentError == nil && priceError == nil }

    func submit(spot: Spot, env: AppEnvironment) async {
        submitted = true
        guard isValid, let user = env.auth.user else { return }
        isBusy = true; error = nil; defer { isBusy = false }
        let c = CheckIn(spotId: spot.id, uid: user.id, pseudo: user.pseudo, noise: noise, crowd: crowd, wifi: wifi, outlets: outlets,
                        coffeePrice: price.isEmpty ? nil : Double(price.replacingOccurrences(of: ",", with: ".")),
                        rating: rating, comment: comment.trimmingCharacters(in: .whitespacesAndNewlines))
        do {
            try await env.data.submit(c, spot: spot)
            let r = XPService.apply(c, to: user)
            try await env.data.updateUser(r.user)
            env.auth.update(r.user)
            result = r
        } catch { self.error = AppError.key(for: error) }
    }
}
