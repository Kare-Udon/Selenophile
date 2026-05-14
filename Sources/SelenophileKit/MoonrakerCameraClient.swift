import Foundation

public protocol MoonrakerCameraClientProtocol: Sendable {
    func fetchSnapshot(configuration: MoonrakerValidatedConfiguration) async throws -> Data
}

public enum MoonrakerCameraError: LocalizedError, Equatable {
    case noSnapshotURL
    case invalidSnapshotResponse

    public var errorDescription: String? {
        switch self {
        case .noSnapshotURL:
            return "Enter an accessible camera snapshot URL first."
        case .invalidSnapshotResponse:
            return "The camera snapshot response is invalid."
        }
    }
}

public final class MoonrakerCameraClient: MoonrakerCameraClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchSnapshot(configuration: MoonrakerValidatedConfiguration) async throws -> Data {
        guard let snapshotRequest = resolvedSnapshotRequest(from: configuration.cameraSnapshotURL, baseURL: configuration.httpURL) else {
            throw MoonrakerCameraError.noSnapshotURL
        }

        var request = URLRequest(url: snapshotRequest.url)
        request.httpMethod = "GET"
        if snapshotRequest.forwardsMoonrakerAuthorization {
            applyAuthorization(to: &request, token: configuration.apiToken)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw MoonrakerCameraError.invalidSnapshotResponse
        }
        return data
    }

    private func applyAuthorization(to request: inout URLRequest, token: String?) {
        guard let token, !token.isEmpty else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func resolvedSnapshotRequest(from snapshotURL: String?, baseURL: URL) -> ResolvedSnapshotRequest? {
        let trimmed = snapshotURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }

        if let absoluteURL = URL(string: trimmed), absoluteURL.scheme != nil {
            return ResolvedSnapshotRequest(
                url: absoluteURL,
                forwardsMoonrakerAuthorization: isSameOrigin(absoluteURL, baseURL)
            )
        }

        let relativeComponents = URLComponents(string: trimmed)
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.port = nil
        let relativePath = relativeComponents?.path ?? trimmed
        components.path = relativePath.hasPrefix("/") ? relativePath : "/" + relativePath
        components.query = relativeComponents?.query
        components.fragment = nil
        guard let url = components.url else { return nil }
        return ResolvedSnapshotRequest(url: url, forwardsMoonrakerAuthorization: true)
    }

    private func isSameOrigin(_ url: URL, _ baseURL: URL) -> Bool {
        url.scheme?.lowercased() == baseURL.scheme?.lowercased()
            && url.host()?.lowercased() == baseURL.host()?.lowercased()
            && normalizedPort(for: url) == normalizedPort(for: baseURL)
    }

    private func normalizedPort(for url: URL) -> Int? {
        if let port = url.port {
            return port
        }

        switch url.scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
    }
}

private struct ResolvedSnapshotRequest {
    let url: URL
    let forwardsMoonrakerAuthorization: Bool
}
