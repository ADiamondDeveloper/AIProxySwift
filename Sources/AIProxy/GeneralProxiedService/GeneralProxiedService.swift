//
//  GeneralProxiedService.swift
//  AIProxy
//
//  Created on 02.04.2026.
//

import Foundation

/// A universal proxied service that can make arbitrary requests through AIProxy
/// to any provider. Request/response bodies are defined on the caller side.
@AIProxyActor public final class GeneralProxiedService: ProxiedService, Sendable {
    private let partialKey: String
    private let serviceURL: String
    private let clientID: String?
    /// Headers attached to every request this service makes. Use the
    /// reserved `aiproxy-key-format` header to plug providers whose auth
    /// scheme isn't `Authorization: Bearer <key>` (e.g. `x-key: {{key}}`
    /// for bfl.ai). `{{key}}` is substituted by AIProxy server-side after
    /// it reassembles the API key from `partialKey`.
    private let additionalHeaders: [String: String]

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.generalService` defined in AIProxy.swift
    nonisolated init(
        partialKey: String,
        serviceURL: String,
        clientID: String?,
        additionalHeaders: [String: String] = [:]
    ) {
        self.partialKey = partialKey
        self.serviceURL = serviceURL
        self.clientID = clientID
        self.additionalHeaders = additionalHeaders
    }

    /// Makes a POST request through AIProxy and deserializes the response.
    ///
    /// - Parameters:
    ///   - path: The API path, e.g. "/v3/remove-background"
    ///   - body: The JSON-encodable request body
    ///   - secondsToWait: Timeout in seconds (default: 60)
    ///   - extraHeaders: Per-request headers merged on top of the service-level
    ///     `additionalHeaders` set on init.
    /// - Returns: The deserialized response of type `R`
    public func post<T: Encodable & Sendable, R: Decodable & Sendable>(
        path: String,
        body: T,
        secondsToWait: UInt = 60,
        extraHeaders: [String: String] = [:]
    ) async throws -> R {
        let bodyData = try JSONEncoder().encode(body)
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: path,
            body: bodyData,
            verb: .post,
            secondsToWait: secondsToWait,
            contentType: "application/json",
            additionalHeaders: self.additionalHeaders.merging(extraHeaders) { _, new in new }
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Makes a GET request through AIProxy and deserializes the response.
    ///
    /// - Parameters:
    ///   - path: The API path, e.g. "/v3/async/task-result?task_id=xxx"
    ///   - secondsToWait: Timeout in seconds (default: 60)
    ///   - extraHeaders: Per-request headers merged on top of the service-level
    ///     `additionalHeaders` set on init.
    /// - Returns: The deserialized response of type `R`
    public func get<R: Decodable & Sendable>(
        path: String,
        secondsToWait: UInt = 60,
        extraHeaders: [String: String] = [:]
    ) async throws -> R {
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: path,
            body: nil,
            verb: .get,
            secondsToWait: secondsToWait,
            contentType: "application/json",
            additionalHeaders: self.additionalHeaders.merging(extraHeaders) { _, new in new }
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Makes a GET request to an absolute URL, bypassing AIProxy entirely.
    /// Useful for self-authenticated polling URLs returned by an earlier
    /// `post`/`get` (e.g. bfl.ai's signed `polling_url` field) — those URLs
    /// already encode their own authorization in query parameters, so
    /// re-routing them through the proxy would just add latency.
    ///
    /// - Parameters:
    ///   - url: The absolute URL returned by the upstream service.
    ///   - secondsToWait: Timeout in seconds (default: 30).
    /// - Returns: The deserialized response of type `R`.
    public func getDirect<R: Decodable & Sendable>(
        url: URL,
        secondsToWait: UInt = 30
    ) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = TimeInterval(secondsToWait)

        let (data, _) = try await BackgroundNetworker.makeRequestAndWaitForData(
            URLSession.shared,
            request
        )
        return try R.deserialize(from: data)
    }

}
