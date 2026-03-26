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
            return "请先填写可访问的相机快照地址。"
        case .invalidSnapshotResponse:
            return "相机快照响应无效。"
        }
    }
}

public final class MoonrakerCameraClient: MoonrakerCameraClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchSnapshot(configuration: MoonrakerValidatedConfiguration) async throws -> Data {
        guard let snapshotURL = resolvedURL(from: configuration.cameraSnapshotURL, baseURL: configuration.httpURL) else {
            throw MoonrakerCameraError.noSnapshotURL
        }

        var request = URLRequest(url: snapshotURL)
        request.httpMethod = "GET"
        applyAuthorization(to: &request, token: configuration.apiToken)

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

    private func resolvedURL(from snapshotURL: String?, baseURL: URL) -> URL? {
        let trimmed = snapshotURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }

        if let absoluteURL = URL(string: trimmed), absoluteURL.scheme != nil {
            return absoluteURL
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
        return components.url
    }
}
