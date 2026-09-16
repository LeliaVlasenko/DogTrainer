import SwiftUI
import SwiftData
import PhotosUI
import ImagePlayground

/// Дозволяє користувачу обрати фото собаки і згенерувати на його основі
/// стилізовану ілюстрацію через Apple's Image Playground (on-device).
/// Результат зберігається у `dog.avatarData`.
@available(iOS 18.1, *)
struct AvatarGeneratorView: View {
    @Bindable var dog: Dog

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var sourceImage: Image? = nil
    @State private var showPlayground = false
    @State private var isLoadingPhoto = false

    // Концепти для playground — підштовхуємо стиль до брендового
    private let concepts: [ImagePlaygroundConcept] = [
        .text("cute friendly dog portrait illustration"),
        .text("flat 2D cartoon style, rounded shapes"),
        .text("warm beige background with sage green accents"),
        .text("Pupcademy brand mascot style")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    ZStack {
                        Circle()
                            .fill(Color.appSage.opacity(0.1))
                            .frame(width: 180, height: 180)
                        DogAvatar(dog: dog, size: 160)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.appSage.opacity(0.3), lineWidth: 2)
                            )
                    }
                    .padding(.top, 8)

                    // Title + sub
                    VStack(spacing: 8) {
                        Text(String(localized: "avatar.generator.title"))
                            .font(.system(size: 22, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(String(localized: "avatar.generator.subtitle"))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)

                    // Capability check
                    if !supportsImagePlayground {
                        UnsupportedBanner()
                    }

                    // Picker
                    PhotosPicker(
                        selection: $pickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label {
                            Text(String(localized: "avatar.generator.choose"))
                                .font(.system(size: 16, weight: .semibold))
                        } icon: {
                            if isLoadingPhoto {
                                SwiftUI.ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(supportsImagePlayground ? Color.accentColor : Color.secondary.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!supportsImagePlayground || isLoadingPhoto)

                    // Tip
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.appGold)
                            .font(.system(size: 14))
                        Text(String(localized: "avatar.generator.tip"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appGold.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.appBackground)
            .navigationTitle(String(localized: "avatar.generator.nav.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "profile.edit.cancel")) {
                        dismiss()
                    }
                }
                if dog.avatarData != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "avatar.generator.reset"), role: .destructive) {
                            dog.avatarData = nil
                            try? modelContext.save()
                        }
                    }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadSourceImage(from: newItem) }
            }
            .imagePlaygroundSheet(
                isPresented: $showPlayground,
                concepts: concepts,
                sourceImage: sourceImage
            ) { url in
                Task { await saveGeneratedAvatar(from: url) }
            } onCancellation: {
                sourceImage = nil
                pickerItem = nil
            }
        }
    }

    // MARK: - Logic

    @MainActor
    private func loadSourceImage(from item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else { return }
        sourceImage = Image(uiImage: ui)
        // Playground відкривається тільки якщо доступний на пристрої
        if supportsImagePlayground {
            showPlayground = true
        }
    }

    @MainActor
    private func saveGeneratedAvatar(from url: URL) async {
        guard let data = try? Data(contentsOf: url) else { return }
        dog.avatarData = data
        try? modelContext.save()
        // Прибираємо тимчасовий файл playground
        try? FileManager.default.removeItem(at: url)
        dismiss()
    }
}

// MARK: - Unsupported banner

private struct UnsupportedBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.appFlame)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "avatar.generator.unsupported.title"))
                    .font(.system(size: 13, weight: .semibold))
                Text(String(localized: "avatar.generator.unsupported.body"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appFlame.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.appFlame.opacity(0.25), lineWidth: 1)
        )
    }
}
