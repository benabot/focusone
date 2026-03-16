import SwiftUI

struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.spacingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }
}

struct AppSurface<Content: View>: View {
    let padding: CGFloat
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(padding: CGFloat = AppSpacing.m, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(AppColors.surface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.82), lineWidth: 1)
            )
    }
}

struct AppSectionTitle: View {
    let title: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(title)
            .font(AppTypography.section)
            .foregroundStyle(AppColors.textSecondary(for: colorScheme))
    }
}

struct OnboardingFeatureCard<Visual: View>: View {
    let title: String
    let message: String
    let accentHex: String
    let visual: Visual

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        message: String,
        accentHex: String = Theme.defaultThemeHex,
        @ViewBuilder visual: () -> Visual
    ) {
        self.title = title
        self.message = message
        self.accentHex = accentHex
        self.visual = visual()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: accentHex).opacity(0.18),
                                Color.white.opacity(colorScheme == .dark ? 0.10 : 0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 196)

                visual
                    .padding(AppSpacing.m)
            }

            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text(title)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textPrimary(for: colorScheme))

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.68))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.72), lineWidth: 1)
        )
    }
}
