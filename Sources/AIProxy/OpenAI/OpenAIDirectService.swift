//
//  OpenAIDirectService.swift
//
//
//  Created by Lou Zell on 12/14/24.
//

@AIProxyActor final class OpenAIDirectService: OpenAIService, DirectService, Sendable {
    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.directOpenAIService` defined in AIProxy.swift
    nonisolated init(
        unprotectedAPIKey: String,
        requestFormat: OpenAIRequestFormat = .standard,
        baseURL: String? = nil,
        additionalHeaders: [String: String] = [:],
        unprotectedAuthHeader: (key: String, value: String)? = nil
    ) {
        let baseURL = baseURL ?? "https://api.openai.com"
        let requestBuilder = AIProxyDirectRequestBuilder(
            baseURL: baseURL,
            unprotectedAuthHeader: unprotectedAuthHeader ?? (key: "Authorization", value: "Bearer \(unprotectedAPIKey)"),
            extraHeaders: additionalHeaders
        )
        super.init(
            requestFormat: requestFormat,
            requestBuilder: requestBuilder,
            serviceNetworker: DirectServiceNetworker()
        )
    }
}
