import SwiftUI

// MARK: - Pupcademy palette
// Warm beige + sage green + gold/orange/coral accents.
// All colors picked from the brand reference illustration.

extension Color {

    // MARK: Backgrounds

    /// Головний бежевий фон екранів.
    static let appBackground       = Color(red: 0.945, green: 0.910, blue: 0.835)   // #F1E8D5
    /// Світліший беж — фон карток.
    static let appCardBackground   = Color(red: 0.972, green: 0.949, blue: 0.894)   // #F8F2E4
    /// Темніший беж — вкладені блоки.
    static let appNestedBackground = Color(red: 0.918, green: 0.878, blue: 0.788)   // #EAE0C9

    // MARK: Brand colors

    /// Sage green — акцент бренду.
    static let appSage   = Color(red: 0.553, green: 0.643, blue: 0.490)   // #8DA47D
    /// Темніший sage — для виокремлень.
    static let appSageDark = Color(red: 0.431, green: 0.518, blue: 0.376) // #6E8460

    /// Тепло-золотий — зірки, трофей, premium.
    static let appGold   = Color(red: 0.910, green: 0.725, blue: 0.282)   // #E8B948
    /// Помаранчевий вогник — streak.
    static let appFlame  = Color(red: 0.910, green: 0.580, blue: 0.337)   // #E89456
    /// Коралово-рожевий — попередження, серце.
    static let appCoral  = Color(red: 0.910, green: 0.604, blue: 0.549)   // #E89A8C
    /// М'який rose — soc-категорія.
    static let appRose   = Color(red: 0.722, green: 0.584, blue: 0.659)   // #B895A8
}
