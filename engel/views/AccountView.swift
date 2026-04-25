//
//  AccountView.swift
//  engel
//

import SwiftUI
import SwiftData

struct AccountView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SDEntry.createdAt, order: .reverse) private var entries: [SDEntry]

    @AppStorage("userName") private var userName = "Arssh K."
    @AppStorage("joinedAt") private var joinedAt: String = ""
    @AppStorage("twoFAEnabled") private var twoFAEnabled = true

    @State private var showLogoutSheet = false
    @State private var showTwoFAAlert = false

    private var maskedPhone: String {
        guard let phone = session.phoneNumber, phone.count >= 4 else {
            return "+1 (•••) ••• ••••"
        }
        let last4 = String(phone.suffix(4))
        return "+1 (•••) ••• \(last4)"
    }

    private var joinDateString: String {
        if joinedAt.isEmpty {
            let now = ISO8601DateFormatter().string(from: Date())
            joinedAt = now
        }
        if let date = ISO8601DateFormatter().date(from: joinedAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        }
        return "recently"
    }

    private var userInitial: String {
        String(userName.prefix(1)).uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    identityCard
                    signInMethodGroup
                    privacyGroup
                    signOutButton
                    footerLine
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 130)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showLogoutSheet) {
            LogoutSheet(isPresented: $showLogoutSheet)
        }
        .alert("Two-factor authentication", isPresented: $showTwoFAAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Required for phone-only auth. This can\u{2019}t be turned off.")
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

            Text("Account")
                .font(AppTypography.display(size: 26, weight: .regular))
                .tracking(-0.3)
                .foregroundStyle(ThemeTokens.colors.ink)

            Spacer()
        }
        .padding(.top, 66)
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    // MARK: - Identity Card

    private var identityCard: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ThemeTokens.colors.green.opacity(0.98),
                            ThemeTokens.colors.greenDeep.opacity(0.92)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 2,
                        endRadius: 36
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Text(userInitial)
                        .font(AppTypography.display(size: 24, weight: .regular))
                        .foregroundStyle(.white)
                )

            // Info
            VStack(alignment: .leading, spacing: 0) {
                Text(userName)
                    .font(AppTypography.display(size: 22, weight: .regular))
                    .tracking(-0.2)
                    .foregroundStyle(ThemeTokens.colors.ink)

                Text(maskedPhone)
                    .font(AppTypography.mono(size: 12, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .padding(.top, 3)

                Text("\(entries.count) fragments \u{00B7} joined \(joinDateString)")
                    .font(AppTypography.mono(size: 11, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .padding(.top, 6)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ThemeTokens.colors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ThemeTokens.colors.line, lineWidth: 1)
                )
        )
    }

    // MARK: - Sign-In Method

    private var signInMethodGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupOverline("SIGN-IN METHOD")

            VStack(spacing: 0) {
                // Phone number row
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Phone number")
                            .font(AppTypography.mono(size: 14, weight: .medium))
                            .foregroundStyle(ThemeTokens.colors.ink)
                        Text("\(maskedPhone) \u{00B7} verified")
                            .font(AppTypography.mono(size: 11, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    Spacer()
                    Circle()
                        .fill(ThemeTokens.colors.green)
                        .frame(width: 6, height: 6)
                }
                .frame(minHeight: 56)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)

                // Divider
                Rectangle()
                    .fill(ThemeTokens.colors.lineSoft)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // 2FA row
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Two-factor authentication")
                            .font(AppTypography.mono(size: 14, weight: .medium))
                            .foregroundStyle(ThemeTokens.colors.ink)
                        Text("SMS code on every new sign-in")
                            .font(AppTypography.mono(size: 11, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .tint(ThemeTokens.colors.green)
                        .disabled(true)
                        .onTapGesture {
                            showTwoFAAlert = true
                        }
                }
                .frame(minHeight: 56)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ThemeTokens.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ThemeTokens.colors.line, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.top, 22)
    }

    // MARK: - Privacy

    private var privacyGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupOverline("PRIVACY")

            VStack(spacing: 0) {
                // Export row
                ShareLink(item: exportText) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Export everything")
                                .font(AppTypography.mono(size: 14, weight: .medium))
                                .foregroundStyle(ThemeTokens.colors.ink)
                            Text("One tap. Always yours.")
                                .font(AppTypography.mono(size: 11, weight: .regular))
                                .foregroundStyle(ThemeTokens.colors.inkDim)
                        }
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .frame(minHeight: 56)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                // Divider
                Rectangle()
                    .fill(ThemeTokens.colors.lineSoft)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // Change phone row
                Button {
                    // Change phone flow — no-op for now
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Change phone number")
                                .font(AppTypography.mono(size: 14, weight: .medium))
                                .foregroundStyle(ThemeTokens.colors.ink)
                            Text("Re-verifies on next sign-in")
                                .font(AppTypography.mono(size: 11, weight: .regular))
                                .foregroundStyle(ThemeTokens.colors.inkDim)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .frame(minHeight: 56)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ThemeTokens.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ThemeTokens.colors.line, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.top, 22)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            showLogoutSheet = true
        } label: {
            Text("SIGN OUT")
                .font(AppTypography.mono(size: 14, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color(hex: 0xC83030))
                .frame(maxWidth: .infinity, minHeight: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ThemeTokens.colors.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 28)
    }

    // MARK: - Footer

    private var footerLine: some View {
        Text("Authority stays with the human.")
            .font(Font.custom("Fraunces", size: 13).italic())
            .foregroundStyle(ThemeTokens.colors.inkDim)
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
    }

    // MARK: - Helpers

    private func groupOverline(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.mono(size: 10, weight: .semibold))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(ThemeTokens.colors.inkDim)
            .padding(.bottom, 10)
            .padding(.leading, 4)
    }

    private var exportText: String {
        var lines = [
            "# Engel Export",
            "",
            "Exported: \(Date().formatted())",
            "Total entries: \(entries.count)",
            ""
        ]

        let grouped: [(String, [SDEntry])] = [
            ("Green", entries.filter { $0.globe == "green" }),
            ("Red", entries.filter { $0.globe == "red" }),
            ("Mixed", entries.filter { $0.globe == "mixed" }),
            ("Unsorted", entries.filter { $0.globe == "unsorted" })
        ]

        for (label, group) in grouped where !group.isEmpty {
            lines.append("## \(label) Globe (\(group.count))")
            lines.append("")
            for entry in group {
                lines.append("- **\(entry.createdAt.formatted(date: .abbreviated, time: .shortened))**")
                lines.append("  \(entry.content)")
                if !entry.pointers.isEmpty {
                    lines.append("  Tags: \(entry.pointers.map { "#\($0)" }.joined(separator: " "))")
                }
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }
}
