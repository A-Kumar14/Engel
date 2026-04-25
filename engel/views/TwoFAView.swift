//
//  TwoFAView.swift
//  engel
//

import Combine
import SwiftUI

struct TwoFAView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @State private var resendSeconds: Int = 38
    @State private var error: String?
    @FocusState private var focusedIndex: Int?

    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var code: String { digits.joined() }
    private var isCodeComplete: Bool { digits.allSatisfy { !$0.isEmpty } }

    private var maskedPhone: String {
        guard let phone = session.phoneNumber, phone.count >= 4 else {
            return "+1 (•••) ••• ••••"
        }
        let last4 = String(phone.suffix(4))
        return "+1 (•••) ••• \(last4)"
    }

    private var activeIndex: Int {
        digits.firstIndex(where: \.isEmpty) ?? 5
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    headlineSection
                    otpBoxes
                    errorSection
                    resendChip
                }
                .padding(.horizontal, 22)
            }

            VStack(spacing: 0) {
                verifyButton
                    .padding(.horizontal, 22)

                differentNumberLink
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { focusedIndex = 0 }
        .onReceive(timer) { _ in
            if resendSeconds > 0 {
                resendSeconds -= 1
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(ThemeTokens.colors.line, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Text("Verify")
                .font(AppTypography.display(size: 26, weight: .regular))
                .tracking(-0.3)
                .foregroundStyle(ThemeTokens.colors.ink)

            Spacer()
        }
        .padding(.top, 66)
        .padding(.bottom, 14)
    }

    // MARK: - Headline

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Enter the code we")
                    .font(AppTypography.display(size: 26, weight: .light))
                    .foregroundStyle(ThemeTokens.colors.ink)

                HStack(spacing: 0) {
                    Text("texted to ")
                        .font(AppTypography.display(size: 26, weight: .light))
                        .foregroundStyle(ThemeTokens.colors.ink)

                    Text(maskedPhone)
                        .font(Font.custom("Fraunces", size: 26).weight(.light).italic())
                        .foregroundStyle(ThemeTokens.colors.ink)
                }
            }
            .tracking(-0.2)
            .lineSpacing(26 * 0.3)
            .padding(.top, 8)

            Text("6 digits, expires in 10 minutes.")
                .font(AppTypography.mono(size: 12, weight: .regular))
                .foregroundStyle(ThemeTokens.colors.inkDim)
                .lineSpacing(12 * 0.5)
                .padding(.top, 12)
        }
    }

    // MARK: - OTP Boxes

    private var otpBoxes: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                otpBox(index: index)
            }
        }
        .padding(.top, 32)
    }

    private func otpBox(index: Int) -> some View {
        let isActive = index == activeIndex && !isCodeComplete
        let hasDigit = !digits[index].isEmpty

        return ZStack {
            // Background box
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ThemeTokens.colors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isActive ? ThemeTokens.colors.ink : ThemeTokens.colors.line,
                            lineWidth: isActive ? 1.5 : 1
                        )
                )

            // Digit display
            if hasDigit {
                Text(digits[index])
                    .font(AppTypography.display(size: 28, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)
            } else if isActive {
                // Blinking caret
                BlinkingCaret()
            }

            // Hidden text field
            TextField("", text: $digits[index])
                .keyboardType(.numberPad)
                .textContentType(index == 0 ? .oneTimeCode : nil)
                .focused($focusedIndex, equals: index)
                .foregroundStyle(.clear)
                .tint(.clear)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: digits[index]) { oldValue, newValue in
                    handleDigitChange(index: index, oldValue: oldValue, newValue: newValue)
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedIndex = isCodeComplete ? 5 : activeIndex
        }
    }

    private func handleDigitChange(index: Int, oldValue: String, newValue: String) {
        // Filter to digits only
        let filtered = newValue.filter(\.isNumber)

        if filtered.isEmpty && oldValue.count > 0 {
            // Backspace — clear and move back
            digits[index] = ""
            if index > 0 {
                focusedIndex = index - 1
            }
            return
        }

        if filtered.count == 1 {
            digits[index] = filtered
            // Advance to next
            if index < 5 {
                focusedIndex = index + 1
            }
        } else if filtered.count > 1 {
            // Pasted code or autofill
            let chars = Array(filtered.prefix(6))
            for (i, char) in chars.enumerated() {
                if i < 6 {
                    digits[i] = String(char)
                }
            }
            focusedIndex = min(chars.count, 5)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error {
            Text(error)
                .font(AppTypography.mono(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0xC83030))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
        }
    }

    // MARK: - Resend Chip

    private var resendChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ThemeTokens.colors.inkDim)

            HStack(spacing: 0) {
                Text("Didn\u{2019}t arrive? ")
                    .font(AppTypography.mono(size: 12, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)

                if resendSeconds > 0 {
                    Text("Resend in 0:\(String(format: "%02d", resendSeconds))")
                        .font(AppTypography.mono(size: 12, weight: .semibold))
                        .foregroundStyle(ThemeTokens.colors.ink)
                } else {
                    Button {
                        Task {
                            guard let phone = session.phoneNumber else { return }
                            try? await session.sendCode(to: phone)
                            resendSeconds = 60
                        }
                    } label: {
                        Text("Resend now")
                            .font(AppTypography.mono(size: 12, weight: .semibold))
                            .foregroundStyle(ThemeTokens.colors.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ThemeTokens.colors.ink.opacity(0.04))
        )
        .padding(.top, 22)
    }

    // MARK: - Verify Button

    private var verifyButton: some View {
        Button {
            Task {
                do {
                    try await session.verify(code: code)
                } catch _ {
                    self.error = session.error ?? "Verification failed."
                    self.digits = Array(repeating: "", count: 6)
                    self.focusedIndex = 0
                }
            }
        } label: {
            HStack(spacing: 8) {
                if session.isVerifying {
                    ProgressView()
                        .tint(ThemeTokens.colors.bgElevated)
                } else {
                    Text("VERIFY")
                        .font(AppTypography.mono(size: 14, weight: .semibold))
                        .tracking(0.8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(ThemeTokens.colors.bgElevated)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isCodeComplete && !session.isVerifying
                          ? ThemeTokens.colors.ink
                          : ThemeTokens.colors.ink.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isCodeComplete || session.isVerifying)
    }

    // MARK: - Different Number

    private var differentNumberLink: some View {
        Button {
            dismiss()
        } label: {
            Text("Use a different phone number \u{2192}")
                .font(AppTypography.mono(size: 12, weight: .regular))
                .tracking(0.4)
                .foregroundStyle(ThemeTokens.colors.inkDim)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Blinking Caret

private struct BlinkingCaret: View {
    @State private var visible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(ThemeTokens.colors.ink)
            .frame(width: 2, height: 28)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}
