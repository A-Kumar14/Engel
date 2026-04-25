//
//  SessionStore.swift
//  engel
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @AppStorage("isAuthenticated") var isAuthenticated = false
    @AppStorage("storedPhoneNumber") var phoneNumber: String?
    @Published var verificationID: String?
    @Published var error: String?
    @Published var isSendingCode = false
    @Published var isVerifying = false

    func sendCode(to phone: String) async throws {
        isSendingCode = true
        error = nil
        defer { isSendingCode = false }

        // Stub: simulate network delay
        try await Task.sleep(for: .seconds(1))

        // Store a fake verification ID
        verificationID = UUID().uuidString
        phoneNumber = phone
    }

    func verify(code: String) async throws {
        isVerifying = true
        error = nil
        defer { isVerifying = false }

        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            error = "Enter a valid 6-digit code."
            throw AuthError.invalidCode
        }

        // Stub: simulate network delay
        try await Task.sleep(for: .seconds(1))

        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        phoneNumber = nil
        verificationID = nil
        error = nil
    }
}

enum AuthError: LocalizedError {
    case invalidCode
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid verification code."
        case .networkError: return "Something went wrong. Try again."
        }
    }
}
