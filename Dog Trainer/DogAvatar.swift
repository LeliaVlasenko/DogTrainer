import SwiftUI

/// Уніфікований аватар собаки: якщо є кастомне фото у `dog.avatarData` —
/// показує його, інакше — fallback на `BrandIcon` для рівня (puppy/adult/guide).
struct DogAvatar: View {
    let dog: Dog
    let size: CGFloat

    var body: some View {
        if let data = dog.avatarData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            BrandIcon(dog.level.iconName, size: size)
        }
    }
}
