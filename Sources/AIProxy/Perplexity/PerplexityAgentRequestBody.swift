//
//  PerplexityAgentRequestBody.swift
//  AIProxy
//
//  Created for Perplexity Agent API (`POST /v1/agent`).
//

import Foundation

/// Request body for Perplexity's Agent API. Different shape than the
/// Chat Completions API: takes a single `input` string (the user
/// query) plus an explicit `tools` array. The agent runtime decides
/// when to invoke each tool (`web_search`, `people_search`,
/// `finance_search`, ...) and returns a structured `output` array.
///
/// Reference: https://docs.perplexity.ai/docs/agent-api/quickstart
public struct PerplexityAgentRequestBody: Encodable, Sendable {
    public let model: String
    public let input: String
    public let tools: [Tool]
    public let instructions: String?
    public let preset: String?
    public let maxOutputTokens: Int?
    public let maxSteps: Int?
    public let reasoning: Reasoning?
    public let temperature: Double?
    public let topP: Double?

    private enum CodingKeys: String, CodingKey {
        case model
        case input
        case tools
        case instructions
        case preset
        case maxOutputTokens = "max_output_tokens"
        case maxSteps        = "max_steps"
        case reasoning
        case temperature
        case topP            = "top_p"
    }

    public init(
        model: String,
        input: String,
        tools: [Tool],
        instructions: String? = nil,
        preset: String? = nil,
        maxOutputTokens: Int? = nil,
        maxSteps: Int? = nil,
        reasoning: Reasoning? = nil,
        temperature: Double? = nil,
        topP: Double? = nil
    ) {
        self.model = model
        self.input = input
        self.tools = tools
        self.instructions = instructions
        self.preset = preset
        self.maxOutputTokens = maxOutputTokens
        self.maxSteps = maxSteps
        self.reasoning = reasoning
        self.temperature = temperature
        self.topP = topP
    }

    /// Reasoning-effort knob for models that support chain-of-thought
    /// (e.g. `openai/gpt-5-mini`). Higher effort = more thinking
    /// tokens before the final answer.
    public struct Reasoning: Encodable, Sendable {
        public let effort: Effort

        public init(effort: Effort) {
            self.effort = effort
        }

        public enum Effort: String, Encodable, Sendable {
            case minimal
            case low
            case medium
            case high
        }
    }

    /// Tool definition. Per-tool budget knobs (max_tokens,
    /// max_tokens_per_page, max_results_per_query,
    /// max_results_per_request) are accepted for `people_search`,
    /// `web_search`, and `finance_search`; `fetch_url` ignores them.
    /// Pass `nil` to let Perplexity's defaults apply.
    public struct Tool: Encodable, Sendable {
        public let type: ToolType
        public let maxTokens: Int?
        public let maxTokensPerPage: Int?
        public let maxResultsPerQuery: Int?
        public let maxResultsPerRequest: Int?

        private enum CodingKeys: String, CodingKey {
            case type
            case maxTokens            = "max_tokens"
            case maxTokensPerPage     = "max_tokens_per_page"
            case maxResultsPerQuery   = "max_results_per_query"
            case maxResultsPerRequest = "max_results_per_request"
        }

        public init(
            type: ToolType,
            maxTokens: Int? = nil,
            maxTokensPerPage: Int? = nil,
            maxResultsPerQuery: Int? = nil,
            maxResultsPerRequest: Int? = nil
        ) {
            self.type = type
            self.maxTokens = maxTokens
            self.maxTokensPerPage = maxTokensPerPage
            self.maxResultsPerQuery = maxResultsPerQuery
            self.maxResultsPerRequest = maxResultsPerRequest
        }

        public static let webSearch     = Tool(type: .webSearch)
        public static let peopleSearch  = Tool(type: .peopleSearch)
        public static let financeSearch = Tool(type: .financeSearch)
        public static let fetchURL      = Tool(type: .fetchURL)
    }

    public enum ToolType: String, Encodable, Sendable {
        case webSearch     = "web_search"
        case peopleSearch  = "people_search"
        case financeSearch = "finance_search"
        case fetchURL      = "fetch_url"
    }
}
