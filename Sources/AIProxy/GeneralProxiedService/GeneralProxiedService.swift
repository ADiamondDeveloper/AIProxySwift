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

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.generalService` defined in AIProxy.swift
    nonisolated init(partialKey: String, serviceURL: String, clientID: String?) {
        self.partialKey = partialKey
        self.serviceURL = serviceURL
        self.clientID = clientID
    }

    /// Makes a POST request through AIProxy and deserializes the response.
    ///
    /// - Parameters:
    ///   - path: The API path, e.g. "/v3/remove-background"
    ///   - body: The JSON-encodable request body
    ///   - secondsToWait: Timeout in seconds (default: 60)
    /// - Returns: The deserialized response of type `R`
    public func post<T: Encodable & Sendable, R: Decodable & Sendable>(
        path: String,
        body: T,
        secondsToWait: UInt = 60
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
            contentType: "application/json"
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Makes a GET request through AIProxy and deserializes the response.
    ///
    /// - Parameters:
    ///   - path: The API path, e.g. "/v3/async/task-result?task_id=xxx"
    ///   - secondsToWait: Timeout in seconds (default: 60)
    /// - Returns: The deserialized response of type `R`
    public func get<R: Decodable & Sendable>(
        path: String,
        secondsToWait: UInt = 60
    ) async throws -> R {
        let request = try await AIProxyURLRequest.create(
            partialKey: self.partialKey,
            serviceURL: self.serviceURL,
            clientID: self.clientID,
            proxyPath: path,
            body: nil,
            verb: .get,
            secondsToWait: secondsToWait,
            contentType: "application/json"
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

}
