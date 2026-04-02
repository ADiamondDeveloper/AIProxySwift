//
//  GeneralDirectService.swift
//  AIProxy
//
//  Created on 02.04.2026.
//

import Foundation

/// A universal direct service that can make arbitrary requests to any provider
/// without routing through AIProxy. Request/response bodies are defined on the caller side.
@AIProxyActor public final class GeneralDirectService: DirectService, Sendable {
    private let baseURL: String
    private let authHeader: String
    private let authValue: String

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.generalDirectService` defined in AIProxy.swift
    nonisolated init(baseURL: String, authHeader: String, authValue: String) {
        self.baseURL = baseURL
        self.authHeader = authHeader
        self.authValue = authValue
    }

    /// Makes a POST request directly to the provider and deserializes the response.
    public func post<T: Encodable & Sendable, R: Decodable & Sendable>(
        path: String,
        body: T,
        secondsToWait: UInt = 60
    ) async throws -> R {
        let bodyData = try JSONEncoder().encode(body)
        let request = try AIProxyURLRequest.createDirect(
            baseURL: self.baseURL,
            path: path,
            body: bodyData,
            verb: .post,
            secondsToWait: secondsToWait,
            contentType: "application/json",
            additionalHeaders: [authHeader: authValue]
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Makes a GET request directly to the provider and deserializes the response.
    public func get<R: Decodable & Sendable>(
        path: String,
        secondsToWait: UInt = 60
    ) async throws -> R {
        let request = try AIProxyURLRequest.createDirect(
            baseURL: self.baseURL,
            path: path,
            body: nil,
            verb: .get,
            secondsToWait: secondsToWait,
            contentType: "application/json",
            additionalHeaders: [authHeader: authValue]
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Makes a GET request to an absolute URL (no auth header).
    /// Useful for self-authenticated polling URLs.
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
