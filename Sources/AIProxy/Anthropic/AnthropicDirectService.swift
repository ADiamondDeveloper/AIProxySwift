//
//  AnthropicDirectService.swift
//
//
//  Created by Lou Zell on 12/13/24.
//

import Foundation

@AIProxyActor final class AnthropicDirectService: AnthropicService, DirectService, Sendable {

    nonisolated init(
        unprotectedAPIKey: String,
        baseURL: String? = nil,
        additionalHeaders: [String: String] = [:],
        unprotectedAuthHeader: (key: String, value: String)? = nil
    ) {
        let baseURL = baseURL ?? "https://api.anthropic.com"
        let requestBuilder = AIProxyDirectRequestBuilder(
            baseURL: baseURL,
            unprotectedAuthHeader: unprotectedAuthHeader ?? (key: "x-api-key", value: unprotectedAPIKey),
            extraHeaders: additionalHeaders
        )
        super.init(
            requestBuilder: requestBuilder,
            serviceNetworker: DirectServiceNetworker()
        )
    }
}
