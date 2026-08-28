import Foundation

public enum OpenAICompatibleEndpointPolicy {
    public static func allows(baseURL: URL) -> Bool {
        guard let scheme = baseURL.scheme?.lowercased(),
              let host = baseURL.host?.lowercased(),
              !host.isEmpty else {
            return false
        }

        if scheme == "https" {
            return true
        }

        guard scheme == "http" else {
            return false
        }

        return isLoopbackHost(host)
    }

    private static func isLoopbackHost(_ host: String) -> Bool {
        host == "localhost" ||
            host.hasSuffix(".localhost") ||
            host.hasPrefix("127.") ||
            host == "::1"
    }
}
