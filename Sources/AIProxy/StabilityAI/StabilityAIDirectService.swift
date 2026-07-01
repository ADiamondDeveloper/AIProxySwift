//
//  StabilityAIDirectService.swift
//  
//
//  Created by Lou Zell on 12/15/24.
//

import Foundation

@AIProxyActor final class StabilityAIDirectService: StabilityAIService, DirectService, Sendable {
    private let unprotectedAPIKey: String
    private let baseURL: String
    private let additionalHeaders: [String: String]
    private let unprotectedAuthHeader: (key: String, value: String)?

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.directStabilityAIService` defined in AIProxy.swift
    nonisolated init(
        unprotectedAPIKey: String,
        baseURL: String? = nil,
        additionalHeaders: [String: String] = [:],
        unprotectedAuthHeader: (key: String, value: String)? = nil
    ) {
        self.unprotectedAPIKey = unprotectedAPIKey
        self.baseURL = baseURL ?? "https://api.stability.ai"
        self.additionalHeaders = additionalHeaders
        self.unprotectedAuthHeader = unprotectedAuthHeader
    }

    /// Initiates a request to /v2beta/stable-image/generate/ultra
    ///
    /// - Parameters:
    ///   - body: The request body to send to aiproxy and StabilityAI. See this reference:
    ///           https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1ultra/post
    /// - Returns: The response as StabilityAIUltraResponse, wth image binary data stored on
    ///            the `imageData` property
    public func ultraRequest(
        body: StabilityAIUltraRequestBody
    ) async throws -> StabilityAIImageResponse {
        return try await self.stabilityRequestCommon(
            body: body,
            path: "/v2beta/stable-image/generate/ultra"
        )
    }

    /// Initiates a request to /v2beta/stable-image/generate/sd3
    ///
    /// - Parameters:
    ///   - body: The request body to send to aiproxy and StabilityAI. See this reference:
    ///           https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post
    /// - Returns: The response as StabilityAIUltraResponse, wth image binary data stored on
    ///            the `imageData` property
    public func stableDiffusionRequest(
        body: StabilityAIStableDiffusionRequestBody
    ) async throws -> StabilityAIImageResponse {
        return try await self.stabilityRequestCommon(
            body: body,
            path: "/v2beta/stable-image/generate/sd3"
        )
    }

    public func stabilityRequestCommon<T: MultipartFormEncodable>(
        body: T,
        path: String
    ) async throws -> StabilityAIImageResponse {
        let boundary = UUID().uuidString
        // Auth-header override (same contract as OpenAIDirectService): when set,
        // it REPLACES the provider-native `Authorization: Bearer` slot — used by
        // transit proxies that authenticate with their own header + swap in the
        // real Stability key server-side.
        let auth = self.unprotectedAuthHeader
            ?? (key: "Authorization", value: "Bearer \(self.unprotectedAPIKey)")
        var headers = self.additionalHeaders
        headers["Accept"] = "image/*"
        headers[auth.key] = auth.value
        let request = try AIProxyURLRequest.createDirect(
            baseURL: self.baseURL,
            path: path,
            body: formEncode(body, boundary),
            verb: .post,
            secondsToWait: 60,
            contentType: "multipart/form-data; boundary=\(boundary)",
            additionalHeaders: headers
        )
        let (data, httpResponse) = try await BackgroundNetworker.makeRequestAndWaitForData(
            self.urlSession,
            request
        )
        return StabilityAIImageResponse(
            imageData: data,
            contentType: httpResponse.allHeaderFields["Content-Type"] as? String,
            finishReason: httpResponse.allHeaderFields["finish-reason"] as? String,
            seed: httpResponse.allHeaderFields["seed"] as? String
        )
    }
}
