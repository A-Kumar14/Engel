//
//  LogoutSheet.swift
//  engel
//

import SwiftUI

struct LogoutSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var session: SessionStore

    private let dangerColor = Color(hex: 0xC83030)

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 12)

            // Icon header
            VStack(spacing: 14) {
                Circle()
                    .fill(dangerColor.opacity(0.08))
                    .overlay(
                        Circle()
                            .stroke(dangerColor.opacity(0.18), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(dangerColor)
                    )
                    .frame(width: 64, height: 64)

                Text("Sign out of Engel?")
                    .font(AppTypography.display(size: 24, weight: .regular))
                    .tracking(-0.2)
                    .foregroundStyle(ThemeTokens.colors.ink)

                Text("Your fragments stay on this device.\nYou\u{2019}ll need to verify with SMS to come back.")
                    .font(AppTypography.mono(size: 13, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .lineSpacing(13 * 0.55)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            // Kept / Ends list
            VStack(spacing: 0) {
                statusRow(label: "Local entries & insights", kept: true, isFirst: true)
                statusRow(label: "Settings & appearance", kept: true, isFirst: false)
                statusRow(label: "Active session on this device", kept: false, isFirst: false)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ThemeTokens.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(ThemeTokens.colors.line, lineWidth: 1)
                    )
            )
            .padding(.top, 22)

            // Action buttons
            VStack(spacing: 10) {
                // Sign out
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    session.signOut()
                    isPresented = false
                } label: {
                    Text("SIGN OUT")
                        .font(AppTypography.mono(size: 14, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(dangerColor)
                        )
                }
                .buttonStyle(.plain)

                // Stay signed in
                Button {
                    isPresented = false
                } label: {
                    Text("STAY SIGNED IN")
                        .font(AppTypography.mono(size: 14, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(ThemeTokens.colors.ink)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(ThemeTokens.colors.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 22)

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 38)
        .background(Color(.systemBackground).ignoresSafeArea())
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Status Row

    private func statusRow(label: String, kept: Bool, isFirst: Bool) -> some View {
        VStack(spacing: 0) {
            if !isFirst {
                Rectangle()
                    .fill(ThemeTokens.colors.lineSoft)
                    .frame(height: 1)
            }

            HStack(spacing: 10) {
                // Icon circle
                Circle()
                    .fill(kept
                          ? ThemeTokens.colors.green.opacity(0.2)
                          : dangerColor.opacity(0.12))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: kept ? "checkmark" : "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(kept
                                             ? ThemeTokens.colors.greenDeep
                                             : dangerColor)
                    )

                // Label
                Text(label)
                    .font(AppTypography.mono(size: 13, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)

                Spacer()

                // Status pill
                Text(kept ? "KEPT" : "ENDS")
                    .font(AppTypography.mono(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(kept
                                     ? ThemeTokens.colors.greenDeep
                                     : dangerColor)
            }
            .frame(minHeight: 32)
            .padding(.vertical, 8)
        }
    }
}
