//
//  BackendClient.swift
//  engel
//

import Foundation

struct BackendClient {
    let baseURL: URL
    let session: URLSession

    /// When true, transcribeAudio returns mock data instead of hitting the real endpoint.
    static var devMode = true

    init(
        baseURL: URL = URL(string: "http://127.0.0.1:8000")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchHealth() async throws -> HealthResponse {
        try await request(path: "/api/health")
    }

    func fetchEntries() async throws -> [Entry] {
        try await request(path: "/api/entries")
    }

    func fetchInsights() async throws -> [Insight] {
        try await request(path: "/api/insights")
    }

    func createEntry(_ payload: EntryCreateRequest) async throws -> Entry {
        try await request(path: "/api/entries", method: "POST", body: payload)
    }

    func generateWeeklyInsight() async throws -> Insight {
        try await request(path: "/api/insights/weekly", method: "POST")
    }

    func transcribeAudio(fileURL: URL) async throws -> TranscriptResponse {
        if Self.devMode {
            try await Task.sleep(for: .seconds(1))
            return TranscriptResponse(
                transcript: "This is a simulated voice memo for development testing.",
                suggestedGlobe: .green,
                suggestedPointers: ["testing", "dev"],
                confidence: 0.82
            )
        }

        let url = baseURL.appending(path: "/api/transcribe")
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: fileURL)
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw BackendError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        return try DecoderFactory.make().decode(TranscriptResponse.self, from: data)
    }

    private func request<Response: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw BackendError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        return try DecoderFactory.make().decode(Response.self, from: data)
    }
}

enum BackendError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The backend returned an invalid response."
        case let .serverError(statusCode, message):
            return message ?? "The backend returned status code \(statusCode)."
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

private enum DecoderFactory {
    static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: value) {
                return date
            }

            if let date = ISO8601DateFormatter.standard.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date string: \(value)"
            )
        }
        return decoder
    }
}

private extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
