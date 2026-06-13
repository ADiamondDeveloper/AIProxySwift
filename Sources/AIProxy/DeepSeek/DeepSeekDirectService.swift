//
//  DeepSeekDirectService.swift
//  AIProxy
//
//  Created by Lou Zell on 1/27/25.
//

import Foundation

@AIProxyActor final class DeepSeekDirectService: DeepSeekService, DirectService, Sendable {
    private let unprotectedAPIKey: String
    private let baseURL: String
    private let additionalHeaders: [String: String]
    private let authHeader: (key: String, value: String)

    /// This initializer is not public on purpose.
    /// Customers are expected to use the factory `AIProxy.directDeepSeekService` defined in AIProxy.swift
    nonisolated init(
        unprotectedAPIKey: String,
        baseURL: String? = nil,
        additionalHeaders: [String: String] = [:],
        unprotectedAuthHeader: (key: String, value: String)? = nil
    ) {
        self.unprotectedAPIKey = unprotectedAPIKey
        self.baseURL = baseURL ?? "https://api.deepseek.com"
        self.additionalHeaders = additionalHeaders
        self.authHeader = unprotectedAuthHeader ?? (key: "Authorization", value: "Bearer \(unprotectedAPIKey)")
    }

    /// Caller-supplied headers attached to every request, with the auth header
    /// (default or overridden) taking precedence.
    private nonisolated var requestHeaders: [String: String] {
        self.additionalHeaders.merging([
            self.authHeader.key: self.authHeader.value,
            "Accept": "application/json"
        ]) { _, native in native }
    }

    /// Initiates a non-streaming chat completion request to /chat/completions.
    ///
    /// - Parameters:
    ///   - body: The request body to send to DeepSeek. See this reference:
    ///           https://api-docs.deepseek.com/api/create-chat-completion
    ///   - secondsToWait: The amount of time to wait before `URLError.timedOut` is raised
    /// - Returns: The chat response. See this reference:
    ///            https://api-docs.deepseek.com/api/create-chat-completion#responses
    public func chatCompletionRequest(
        body: DeepSeekChatCompletionRequestBody,
        secondsToWait: UInt
    ) async throws -> DeepSeekChatCompletionResponseBody {
        var body = body
        body.stream = false
        body.streamOptions = nil
        let request = try AIProxyURLRequest.createDirect(
            baseURL: self.baseURL,
            path: "/chat/completions",
            body: try body.serialize(),
            verb: .post,
            secondsToWait: secondsToWait,
            contentType: "application/json",
            additionalHeaders: self.requestHeaders
        )
        return try await self.makeRequestAndDeserializeResponse(request)
    }

    /// Initiates a streaming chat completion request to /chat/completions.
    ///
    /// - Parameters:
    ///   - body: The request body to send to DeepSeek.  See this reference:
    ///           https://api-docs.deepseek.com/api/create-chat-completion
    ///   - secondsToWait: The amount of time to wait before `URLError.timedOut` is raised
    /// - Returns: An async sequence of completion chunks. See the 'Streaming' tab here:
    ///           https://api-docs.deepseek.com/api/create-chat-completion#responses
    public func streamingChatCompletionRequest(
        body: DeepSeekChatCompletionRequestBody,
        secondsToWait: UInt
    ) async throws -> AsyncThrowingStream<DeepSeekChatCompletionChunk, Error> {
        var body = body
        body.stream = true
        body.streamOptions = .init(includeUsage: true)
        let request = try AIProxyURLRequest.createDirect(
            baseURL: self.baseURL,
            path: "/chat/completions",
            body: try body.serialize(),
            verb: .post,
            secondsToWait: secondsToWait,
            contentType: "application/json",
            additionalHeaders: self.requestHeaders
        )
        return try await self.makeRequestAndDeserializeStreamingChunks(request)
    }
}
