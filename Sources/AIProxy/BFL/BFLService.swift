//
//  BFLService.swift
//  AIProxy
//
//  Created on 27.03.2026.
//

import Foundation

@AIProxyActor public protocol BFLService: Sendable {

    /// Submits an image generation request to BFL API.
    ///
    /// - Parameters:
    ///   - body: The JSON-encodable request body
    ///   - path: The API path, e.g. "/v1/flux-kontext-pro"
    /// - Returns: A BFLSubmitResponse containing the task ID and polling URL
    func submitRequest<T: Encodable & Sendable>(
        body: T,
        path: String
    ) async throws -> BFLSubmitResponse

    /// Polls for a task result using an absolute polling URL (no auth required).
    ///
    /// - Parameters:
    ///   - pollingURL: The absolute polling URL returned by BFL in the submit response
    /// - Returns: A BFLTaskResponse with the current status and optional result
    func pollResult(
        pollingURL: URL
    ) async throws -> BFLTaskResponse
}
