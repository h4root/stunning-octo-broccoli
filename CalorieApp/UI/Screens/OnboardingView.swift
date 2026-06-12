import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
}

struct OnboardingView: View {
    var onFinish: () -> Void

    @AppStorage("profile.name") private var name = ""
    @State private var index = 0
    @FocusState private var nameFocused: Bool

    private let pages: [OnboardingPage] = [
        .init(icon: "flame.fill",
              title: "Считай калории легко",
              subtitle: "КБЖУ за день в одном экране — кольца показывают, сколько осталось до цели.",
              tint: Theme.accentPink),
        .init(icon: "barcode.viewfinder",
              title: "Сканируй штрихкоды",
              subtitle: "Наведи камеру на упаковку — продукт подтянется из базы Open Food Facts. Останется подтвердить порцию.",
              tint: Theme.accentPurple),
        .init(icon: "target",
              title: "Свои цели",
              subtitle: "Настрой дневные нормы калорий, белков, жиров и углеводов под себя.",
              tint: Theme.lime)
    ]

    private var lastIndex: Int { pages.count }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        PageView(page: page, isActive: index == i).tag(i)
                    }
                    namePage.tag(lastIndex)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: index)

                pageDots.padding(.bottom, 24)
                button.padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var namePage: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundStyle(Theme.accentPink)
                .frame(width: 150, height: 150)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.glassStroke, lineWidth: 1))
                .shadow(color: Theme.accentPink.opacity(0.4), radius: 24)

            VStack(spacing: 14) {
                Text("Как вас зовут?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Будем здороваться при входе. Можно изменить в профиле.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                TextField("Имя", text: $name)
                    .focused($nameFocused)
                    .multilineTextAlignment(.center)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Theme.glassStroke, lineWidth: 1))
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
            Spacer(); Spacer()
        }
        .padding(.top, 60)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Theme.accentPink : Color.white.opacity(0.2))
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
            }
        }
    }

    private var button: some View {
        Button {
            if index < lastIndex {
                withAnimation { index += 1 }
            } else {
                nameFocused = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onFinish()
            }
        } label: {
            Text(index < lastIndex ? "Далее" : "Начать")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct PageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(page.tint)
                .frame(width: 150, height: 150)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.glassStroke, lineWidth: 1))
                .shadow(color: page.tint.opacity(0.4), radius: 24)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            Spacer(); Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview {
    OnboardingView {}
}
