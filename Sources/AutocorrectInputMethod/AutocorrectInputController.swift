import AppKit
import AutocorrectCore
import AutocorrectProviders
import AutocorrectSettings
import InputMethodKit

@objc(AutocorrectInputController)
final class AutocorrectInputController: IMKInputController {
    private static let insertionPoint = NSRange(location: NSNotFound, length: NSNotFound)
    private static let settingsCache = RuntimeSettingsCache()
    private static let credentialStore: ProviderCredentialStore = LocalCredentialStore()

    private var activeClientID: ObjectIdentifier?
    private var pendingCorrections = PendingCorrectionLedger()

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let string, let sender else {
            return false
        }

        let client = sender as AnyObject
        let clientID = ObjectIdentifier(client)
        synchronizeSession(with: clientID)

        let isBoundary = WordBoundaryDetector.triggersCorrection(for: string)

        // Ordinary input is never text-inspected. We only track its document mutation
        // so outstanding correction ranges can stay anchored while the user types.
        guard isBoundary else {
            let selectionBeforeInsertion = IMKClientBridge.selectedRange(client: client)
            IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
            recordUserMutation(
                replacing: selectionBeforeInsertion,
                withUTF16Length: string.utf16.count
            )
            return true
        }

        let runtimeSettings = Self.settingsCache.current
        guard runtimeAllowsCorrection(runtimeSettings),
              let providerConfiguration = RuntimeProviderFactory.configuration(from: runtimeSettings) else {
            pendingCorrections.cancelAll()
            IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
            return true
        }

        // A correction boundary is the only point where surrounding text is inspected.
        // Fail closed before reading it if the focused field is secure or unverifiable.
        guard AccessibilityGate.safeFocusedField() != nil else {
            pendingCorrections.cancelAll()
            IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
            return true
        }

        let selectionBeforeInsertion = IMKClientBridge.selectedRange(client: client)
        let snapshot = WordSnapshot.capture(from: client)

        // The boundary reaches the client immediately. No spell checking, credential lookup,
        // or network work is allowed to delay normal typing.
        IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
        recordUserMutation(
            replacing: selectionBeforeInsertion,
            withUTF16Length: string.utf16.count
        )

        guard let snapshot else {
            return true
        }

        let isKnownWord = NSSpellChecker.shared
            .checkSpelling(of: snapshot.original, startingAt: 0)
            .location == NSNotFound

        guard CorrectionCandidatePolicy.shouldRequestCorrection(
            completedWord: snapshot.original,
            leftContext: snapshot.leftContext,
            isKnownWord: isKnownWord
        ) else {
            return true
        }

        let correctionID = pendingCorrections.register(
            original: snapshot.original,
            range: snapshot.range
        )
        let request = CorrectionRequest(
            completedWord: snapshot.original,
            leftContext: snapshot.leftContext
        )
        let expectedProviderSignature = runtimeSettings.providerConfigurationSignature
        let correctionProvider = RuntimeProviderFactory.provider(
            configuration: providerConfiguration,
            credentialStore: Self.credentialStore
        )

        Task { [weak self] in
            do {
                let response = try await correctionProvider.correct(request)
                guard let replacement = CorrectionResponsePolicy.validatedReplacement(
                    original: snapshot.original,
                    proposed: response.replacement
                ) else {
                    DispatchQueue.main.async {
                        self?.pendingCorrections.cancel(correctionID)
                    }
                    return
                }

                DispatchQueue.main.async {
                    self?.apply(
                        replacement: replacement,
                        correctionID: correctionID,
                        expectedClientID: clientID,
                        expectedProviderSignature: expectedProviderSignature
                    )
                }
            } catch {
                // Provider failures are pass-through. Never log the error here because
                // provider implementations may evolve and typing data must stay out of logs.
                DispatchQueue.main.async {
                    self?.pendingCorrections.cancel(correctionID)
                }
            }
        }

        return true
    }

    private func synchronizeSession(with clientID: ObjectIdentifier) {
        guard activeClientID != clientID else {
            return
        }

        pendingCorrections.cancelAll()
        activeClientID = clientID
    }

    private func runtimeAllowsCorrection(_ settings: AutocorrectSettingsSnapshot) -> Bool {
        guard settings.isEnabled, settings.privacyAcknowledged else {
            return false
        }

        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return true
        }

        return !settings.excludedBundleIdentifiers.contains(bundleIdentifier)
    }

    private func recordUserMutation(replacing range: NSRange, withUTF16Length newLength: Int) {
        guard range.location != NSNotFound else {
            pendingCorrections.cancelAll()
            return
        }

        pendingCorrections.recordMutation(
            TextMutation(range: range, replacementUTF16Length: newLength)
        )
    }

    private func apply(
        replacement: String,
        correctionID: PendingCorrectionID,
        expectedClientID: ObjectIdentifier,
        expectedProviderSignature: String
    ) {
        let currentSettings = Self.settingsCache.current
        guard runtimeAllowsCorrection(currentSettings),
              currentSettings.providerConfigurationSignature == expectedProviderSignature else {
            pendingCorrections.cancel(correctionID)
            return
        }

        guard let currentClient = client() else {
            pendingCorrections.cancel(correctionID)
            return
        }

        let currentClientObject = currentClient as AnyObject
        let currentClientID = ObjectIdentifier(currentClientObject)
        guard currentClientID == expectedClientID,
              activeClientID == expectedClientID else {
            pendingCorrections.cancel(correctionID)
            return
        }

        // Re-check the privacy boundary at completion time because focus may have moved
        // into a password or secure field while the asynchronous job was pending.
        guard let fieldAccess = AccessibilityGate.safeFocusedField() else {
            pendingCorrections.cancelAll()
            return
        }

        guard let job = pendingCorrections.job(for: correctionID) else {
            return
        }

        guard IMKClientBridge.string(range: job.range, client: currentClientObject) == job.original else {
            pendingCorrections.cancel(correctionID)
            return
        }

        let selection = IMKClientBridge.selectedRange(client: currentClientObject)
        guard selection.location != NSNotFound,
              selection.length == 0,
              !caretIsInside(selection.location, range: job.range),
              fieldAccess.preflightCollapsedSelection(location: selection.location) else {
            pendingCorrections.cancel(correctionID)
            return
        }

        let rebasedCaret = SelectionMath.rebasedCaret(
            selection.location,
            replacing: job.range,
            withUTF16Length: replacement.utf16.count
        )

        IMKClientBridge.insert(
            text: replacement,
            replacing: job.range,
            client: currentClientObject
        )

        guard fieldAccess.restoreCollapsedSelection(location: rebasedCaret) else {
            let replacementRange = NSRange(
                location: job.range.location,
                length: replacement.utf16.count
            )
            IMKClientBridge.insert(
                text: job.original,
                replacing: replacementRange,
                client: currentClientObject
            )
            _ = fieldAccess.restoreCollapsedSelection(location: selection.location)
            pendingCorrections.cancel(correctionID)
            return
        }

        pendingCorrections.commit(
            correctionID,
            replacementUTF16Length: replacement.utf16.count
        )
    }

    private func caretIsInside(_ caret: Int, range: NSRange) -> Bool {
        caret > range.location && caret < NSMaxRange(range)
    }
}
