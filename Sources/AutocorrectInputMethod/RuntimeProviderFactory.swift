import AutocorrectProviders
import AutocorrectSettings
import Foundation

struct RuntimeProviderFactory {
    static func configuration(
        from settings: AutocorrectSettingsSnapshot
    ) -> OpenAICompatibleProviderConfiguration? {
        switch settings.selectedProvider {
        case .gemini:
            let model = settings.geminiModel.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !model.isEmpty else { return nil }
            return ProviderPresets.gemini(model: model)

        case .openRouter:
            let model = settings.openRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !model.isEmpty else { return nil }
            return ProviderPresets.openRouter(model: model)

        case .custom:
            let model = settings.customModel.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseURLString = settings.customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !model.isEmpty,
                  let baseURL = URL(string: baseURLString),
                  OpenAICompatibleEndpointPolicy.allows(baseURL: baseURL) else {
                return nil
            }

            return ProviderPresets.custom(
                identifier: CorrectionProviderSelection.custom.rawValue,
                displayName: CorrectionProviderSelection.custom.displayName,
                baseURL: baseURL,
                model: model
            )
        }
    }

    static func provider(
        configuration: OpenAICompatibleProviderConfiguration,
        credentialStore: ProviderCredentialStore
    ) -> any CorrectionProvider {
        OpenAICompatibleCorrectionProvider(
            configuration: configuration,
            credentialStore: credentialStore
        )
    }
}
