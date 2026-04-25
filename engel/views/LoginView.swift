//
//  LoginView.swift
//  engel
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore

    @State private var phone = ""
    @State private var showVerification = false

    private var digitsOnly: String {
        phone.filter(\.isNumber)
    }

    private var isPhoneValid: Bool {
        digitsOnly.count >= 10
    }

    private var formattedPhone: String {
        formatPhone(digitsOnly)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 84)

                        // Hero globe
                        GlobeView(tone: .green, size: 88, entryCount: 6, pulse: true)
                            .frame(width: 88, height: 88)

                        // Headline
                        headline
                            .padding(.top, 28)

                        // Subheadline
                        VStack(spacing: 2) {
                            Text("Two globes for what you\u{2019}re carrying.")
                            Text("Sign in with your phone \u{2014} that\u{2019}s all we ask.")
                        }
                        .font(AppTypography.mono(size: 12, weight: .regular))
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(12 * 0.5)
                        .padding(.top, 10)

                        Spacer().frame(height: 36)

                        // Phone field
                        phoneFieldSection
                    }
                    .padding(.horizontal, 22)
                }

                // Bottom: send code button + legal
                VStack(spacing: 0) {
                    sendCodeButton
                        .padding(.horizontal, 22)

                    legalText
                        .padding(.horizontal, 22)
                        .padding(.top, 8)
                        .padding(.bottom, 110)
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showVerification) {
                TwoFAView()
            }
        }
    }

    // MARK: - Headline

    private var headline: some View {
        HStack(spacing: 0) {
            Text("Welcome to ")
                .font(AppTypography.display(size: 32, weight: .light))
                .foregroundStyle(ThemeTokens.colors.ink)

            Text("Engel")
                .font(Font.custom("Fraunces", size: 32).weight(.light).italic())
                .foregroundStyle(ThemeTokens.colors.ink)
        }
        .tracking(-0.4)
    }

    // MARK: - Phone Field

    private var phoneFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PHONE NUMBER")
                .font(AppTypography.mono(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(ThemeTokens.colors.inkDim)

            HStack(spacing: 12) {
                TextField("+1 (415) 555 4421", text: $phone)
                    .font(AppTypography.mono(size: 15, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .keyboardType(.phonePad)
                    .onChange(of: phone) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        let formatted = formatPhone(digits)
                        if formatted != newValue {
                            phone = formatted
                        }
                    }

                Image(systemName: "phone")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ThemeTokens.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ThemeTokens.colors.line, lineWidth: 1)
                    )
            )

            if let error = session.error {
                Text(error)
                    .font(AppTypography.mono(size: 11, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.red)
                    .padding(.leading, 4)
            } else {
                Text("We\u{2019}ll text you a 6-digit code. No password ever.")
                    .font(AppTypography.mono(size: 11, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .lineSpacing(11 * 0.45)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: - Send Code Button

    private var sendCodeButton: some View {
        Button {
            Task {
                do {
                    try await session.sendCode(to: digitsOnly)
                    showVerification = true
                } catch {
                    // error is set on session
                }
            }
        } label: {
            HStack(spacing: 8) {
                if session.isSendingCode {
                    ProgressView()
                        .tint(ThemeTokens.colors.bgCard)
                } else {
                    Text("SEND CODE")
                        .font(AppTypography.mono(size: 14, weight: .semibold))
                        .tracking(0.8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(ThemeTokens.colors.bgElevated)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isPhoneValid && !session.isSendingCode
                          ? ThemeTokens.colors.ink
                          : ThemeTokens.colors.ink.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isPhoneValid || session.isSendingCode)
    }

    // MARK: - Legal

    private var legalText: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                Text("By continuing you agree to our ")
                Text("terms")
                    .underline()
                Text(" and ")
                Text("privacy policy")
                    .underline()
                Text(".")
            }

            Text("No prescriptions. No scoring.")
        }
        .font(AppTypography.mono(size: 11, weight: .regular))
        .foregroundStyle(ThemeTokens.colors.inkDim)
        .multilineTextAlignment(.center)
        .lineSpacing(11 * 0.55)
    }

    // MARK: - Phone Formatting

    private func formatPhone(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }

        var result = "+\(digits.prefix(1))"
        if digits.count > 1 {
            let area = digits.dropFirst().prefix(3)
            result += " (\(area)"
            if area.count == 3 { result += ")" }
        }
        if digits.count > 4 {
            let mid = digits.dropFirst(4).prefix(3)
            result += " \(mid)"
        }
        if digits.count > 7 {
            let last = digits.dropFirst(7).prefix(4)
            result += " \(last)"
        }
        return result
    }
}
