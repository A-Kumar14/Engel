//
//  OnboardingView.swift
//  engel
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                loopPage.tag(1)
                philosophyPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Two circles representing the globes
            HStack(spacing: -20) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ThemeTokens.colors.green.opacity(0.9), ThemeTokens.colors.greenDeep],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [ThemeTokens.colors.red.opacity(0.9), ThemeTokens.colors.redDeep],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
            }

            VStack(spacing: 14) {
                Text("Two Globes")
                    .font(AppTypography.display(size: 32, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)

                Text("A green globe for what gives you energy.\nA red globe for what weighs you down.")
                    .font(AppTypography.monoSM)
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var loopPage: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 28) {
                loopStep(icon: "mic.fill", title: "Capture", detail: "Speak or write a fragment")
                loopStep(icon: "arrow.left.arrow.right", title: "Sort", detail: "Place it in a globe")
                loopStep(icon: "number", title: "Tag", detail: "Add pointers to find it later")
                loopStep(icon: "sparkles", title: "Notice", detail: "See one pattern per week")
            }

            VStack(spacing: 8) {
                Text("The Daily Loop")
                    .font(AppTypography.display(size: 28, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)

                Text("Capture first. Meaning comes later.")
                    .font(AppTypography.monoSM)
                    .foregroundStyle(ThemeTokens.colors.inkDim)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var philosophyPage: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                principleRow("No streaks, no scores")
                principleRow("No advice, no diagnoses")
                principleRow("Skip is always valid")
                principleRow("Export in one tap")
                principleRow("You stay in control")
            }

            VStack(spacing: 8) {
                Text("Your space, your rules")
                    .font(AppTypography.display(size: 28, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)

                Text("We notice patterns.\nWe never prescribe.")
                    .font(AppTypography.monoSM)
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            if page > 0 {
                Button {
                    withAnimation { page -= 1 }
                } label: {
                    Text("Back")
                        .font(AppTypography.mono(size: 13, weight: .regular))
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if page < 2 {
                Button {
                    withAnimation { page += 1 }
                } label: {
                    Text("Next")
                        .font(AppTypography.mono(size: 13, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(ThemeTokens.colors.bgElevated)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(ThemeTokens.colors.ink)
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    onComplete()
                } label: {
                    Text("Get Started")
                        .font(AppTypography.mono(size: 13, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(ThemeTokens.colors.bgElevated)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(ThemeTokens.colors.ink)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Components

    private func loopStep(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ThemeTokens.colors.ink.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(ThemeTokens.colors.ink.opacity(0.08))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.mono(size: 14, weight: .semibold))
                    .foregroundStyle(ThemeTokens.colors.ink)

                Text(detail)
                    .font(AppTypography.monoXS)
                    .foregroundStyle(ThemeTokens.colors.inkDim)
            }

            Spacer()
        }
    }

    private func principleRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ThemeTokens.colors.ink.opacity(0.2))
                .frame(width: 6, height: 6)

            Text(text)
                .font(AppTypography.mono(size: 14, weight: .regular))
                .foregroundStyle(ThemeTokens.colors.ink.opacity(0.85))

            Spacer()
        }
    }
}
