import SwiftUI

// MARK: - BrandIcon
// Показує власну ілюстрацію з Assets.xcassets, якщо вона є,
// інакше — fallback emoji. Дозволяє поступово замінювати emoji
// без розбиття UI: додав картинку в Assets — вона автоматично з'явилася.

struct BrandIcon: View {
    let name: BrandIconName
    let size: CGFloat

    init(_ name: BrandIconName, size: CGFloat = 32) {
        self.name = name
        self.size = size
    }

    var body: some View {
        if UIImage(named: name.assetName) != nil {
            Image(name.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(name.fallbackEmoji)
                .font(.system(size: size * 0.9))
        }
    }
}

// MARK: - Каталог іконок бренду

enum BrandIconName {
    // Dog levels
    case dogPuppy        // 🐶
    case dogAdult        // 🐕
    case dogGuide        // 🦮

    // Brand / illustrations
    case paw             // 🐾
    case graduation      // 🎓

    // Streak / progress
    case flame           // 🔥
    case sleep           // 💤
    case trophy          // 🏆

    // Mood
    case star            // 🌟
    case moodGood        // 😊
    case moodOkay        // 😐
    case moodBad         // 😔

    // Achievements
    case muscle          // 💪
    case thumbsUp        // 👍
    case confetti        // 🎉

    /// Назва assets — використовуй для іменування картинок у Assets.xcassets
    var assetName: String {
        switch self {
        case .dogPuppy:    return "icon-dog-puppy"
        case .dogAdult:    return "icon-dog-adult"
        case .dogGuide:    return "icon-dog-guide"
        case .paw:         return "icon-paw"
        case .graduation:  return "icon-graduation"
        case .flame:       return "icon-flame"
        case .sleep:       return "icon-sleep"
        case .trophy:      return "icon-trophy"
        case .star:        return "icon-star"
        case .moodGood:    return "icon-mood-good"
        case .moodOkay:    return "icon-mood-okay"
        case .moodBad:     return "icon-mood-bad"
        case .muscle:      return "icon-muscle"
        case .thumbsUp:    return "icon-thumbs-up"
        case .confetti:    return "icon-confetti"
        }
    }

    /// Fallback emoji, якщо картинку ще не додано в Assets
    var fallbackEmoji: String {
        switch self {
        case .dogPuppy:    return "🐶"
        case .dogAdult:    return "🐕"
        case .dogGuide:    return "🦮"
        case .paw:         return "🐾"
        case .graduation:  return "🎓"
        case .flame:       return "🔥"
        case .sleep:       return "💤"
        case .trophy:      return "🏆"
        case .star:        return "🌟"
        case .moodGood:    return "😊"
        case .moodOkay:    return "😐"
        case .moodBad:     return "😔"
        case .muscle:      return "💪"
        case .thumbsUp:    return "👍"
        case .confetti:    return "🎉"
        }
    }
}
