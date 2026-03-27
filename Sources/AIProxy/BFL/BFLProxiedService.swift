//
//  BFLProxiedService.swift
//  AIProxy
//
//  Created on 27.03.2026.
//

import Foundation

@AIProxyActor final class BFLProxiedService: BFLService, ProxiedService, Sendable {
    private let partialKey: String
    private let serviceURL: String
    private let clientID: String?

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.bflService` defined in AIProxy.swift
    nonisolated init(partialKey: String, serviceURL: String, clientID: String?) {
        self.partialKey = partialKey
        self.serviceURL = serviceURL
        self.clientID = clientID
    }

    /// Submits an image generation request through AIProxy to BFL.
    public func submitRequest<T: Encodable & Sendable>(
        body: T,
        path: String
    ) async throws -> BFLSubmitResponse {
        let bodyData = try JSONEncoder().encode(body)
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: path,
            body: bodyData,
            verb: .post,
            secondsToWait: 60,
            contentType: "application/json"
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
        if AIProxy.printResponseBodies {
            logIf(.debug)?.debug(
                """
                Received BFL polling response:
                \(String(data: data, encoding: .utf8) ?? "")
                """
            )
        }
        return try BFLTaskResponse.deserialize(from: data)
    }
}
