import AppKit
import ApplicationServices
import Carbon

struct FocusedFieldAccess {
    let element: AXUIElement

    func restoreCollapsedSelection(location: Int) -> Bool {
        var range = CFRange(location: location, length: 0)
        guard let value = AXValueCreate(.cfRange, &range) else {
            return false
        }

        return AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            value
        ) == .success
    }
}

enum AccessibilityGate {
    /// Returns access only when the focused element can be positively identified
    /// as a non-secure editable text control whose selection is writable.
    static func safeFocusedField() -> FocusedFieldAccess? {
        if IsSecureEventInputEnabled() {
            return nil
        }

        guard AXIsProcessTrusted(),
              let application = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            applicationElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        ) == .success,
              let focusedValue else {
            return nil
        }

        let focusedElement = focusedValue as! AXUIElement

        if stringAttribute(kAXSubroleAttribute, from: focusedElement) == kAXSecureTextFieldSubrole as String {
            return nil
        }

        guard let role = stringAttribute(kAXRoleAttribute, from: focusedElement),
              role == kAXTextFieldRole as String || role == kAXTextAreaRole as String else {
            return nil
        }

        var selectionIsSettable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(
            focusedElement,
            kAXSelectedTextRangeAttribute as CFString,
            &selectionIsSettable
        ) == .success,
              selectionIsSettable.boolValue else {
            return nil
        }

        return FocusedFieldAccess(element: focusedElement)
    }

    private static func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }
}
