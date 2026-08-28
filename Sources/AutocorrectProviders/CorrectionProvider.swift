import Foundation

public struct CorrectionRequest: Sendable, Equatable {
    public let completedWord: String
    public let leftContext: String

    public init(completedWord: String, leftContext: String) {
        self.completedWord = completedWord
        self.leftContext = leftContext
    }
}

public struct CorrectionResponse: Sendable, Equatable {
    public let replacement: String

    public init(replacement: String) {
        self.replacement = replacement
    }
}

public protocol CorrectionProvider: Sendable {
    var identifier: String { get }
    func correct(_ request: CorrectionRequest) async throws -> CorrectionResponse
}

public enum CorrectionProviderError: Error, Equatable {
    case notAuthenticated
    case invalidConfiguration
    case invalidResponse
    case requestFailed(statusCode: Int)
    case emptyResponse
}
