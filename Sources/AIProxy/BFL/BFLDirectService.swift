//
//  BFLDirectService.swift
//  AIProxy
//
//  Created on 27.03.2026.
//

import Foundation

@AIProxyActor final class BFLDirectService: BFLService, DirectService, Sendable {
    private let unprotectedAPIKey: String

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.bflDirectService` defined in AIProxy.swift
    nonisolated init(unprotectedAPIKey: String) {
        self.unprotectedAPIKey = unprotectedAPIKey
    }

    /// Submits an image generation request directly to BFL.
    public func submitRequest<T: Encodable & Sendable>(
        body: T,
        path: String
    ) async throws -> BFLSubmitResponse {
        let bodyData = try JSONEncoder().encode(body)
        let request = try AIProxyURLRequest.createDirect(
            baseURL: "https://api.bfl.ai",
            path: path,
            body: bodyData,
            verb: .post,
            secondsToWait: 60,
            contentType: "application/json",
            additionalHeaders: [
                "x-key": self.unprotectedAPIKey
            ]
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Polls for result using the polling URL returned by BFL.
    /// Polling URLs are self-authenticated — no API key needed.
    public func pollResult(
        pollingURL: URL
    ) async throws -> BFLTaskResponse {
        var request = URLRequest(url: pollingURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 30

        let (data, _) = try await BackgroundNetworker.makeRequestAndWaitForData(
            URLSession.shared,
            request
        )
        return try BFLTaskResponse.deserialize(from: data)
    }
}
