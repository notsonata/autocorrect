import Foundation
import Security

public enum SharedKeychainAccessGroup {
    public static let suffix = "dev.notsonata.autocorrect.shared"

    private static let applicationGroupsEntitlement = "com.apple.security.application-groups"

    public static func current() -> String? {
        guard let task = SecTaskCreateFromSelf(nil),
              let value = SecTaskCopyValueForEntitlement(
                  task,
                  applicationGroupsEntitlement as CFString,
                  nil
              ),
              let groups = value as? [String] else {
            return nil
        }

        return select(from: groups)
    }

    static func select(from groups: [String]) -> String? {
        groups.first { group in
            group == suffix || group.hasSuffix(".\(suffix)")
        }
    }
}
