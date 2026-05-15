//
//  OpenAICreateImageStreamingEvent.swift
//
//  Created for streaming /v1/images/generations AND /v1/images/edits
//  responses with partial_images. Both endpoints emit chunks with the same
//  payload shape, differing only by the `type` discriminator prefix:
//  `image_generation.*` for /generations, `image_edit.*` for /edits.
//  https://platform.openai.com/docs/api-reference/images/createImage
//  https://platform.openai.com/docs/api-reference/images/createImageEdit
//

import Foundation

/// One Server-Sent Event from the streaming `/v1/images/generations` endpoint.
/// OpenAI emits zero or more `.partialImage` events followed by exactly one
/// `.completed` event. The discriminator is the `type` field on each chunk.
///
/// All payload fields are optional because the live API doesn't always
/// include every field in every chunk (e.g. early `partial_image` events
/// may omit `partial_image_index`). Decoding a chunk should never fail
/// just because a field is missing, otherwise AIProxy's stream parser
/// silently swallows the event and the caller sees nothing.
nonisolated public enum OpenAICreateImageStreamingEvent: Decodable, Sendable {

    /// Lower-resolution preview emitted while the final image is still rendering.
    case partialImage(PartialImage)

    /// Final, full-resolution image, plus token usage.
    case completed(Completed)

    /// Lower-resolution streaming preview.
    nonisolated public struct PartialImage: Decodable, Sendable {
        /// Base64-encoded image bytes for this partial frame.
        public let b64JSON: String?
        /// 0-indexed position of this partial in the stream (0..<partialImages).
        public let partialImageIndex: Int?
        /// Echoed from the request body.
        public let background: String?
        public let outputFormat: String?
        public let quality: String?
        public let size: String?
        public let createdAt: Int?

        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
            case partialImageIndex = "partial_image_index"
            case background
            case outputFormat = "output_format"
            case quality
            case size
            case createdAt = "created_at"
        }
    }

    /// Final image plus usage info. `b64JSON` may be missing on the final
    /// chunk if the API stops at the last partial — callers should fall back
    /// to the most recent `.partialImage` payload in that case.
    nonisolated public struct Completed: Decodable, Sendable {
        public let b64JSON: String?
        public let background: String?
        public let outputFormat: String?
        public let quality: String?
        public let size: String?
        public let createdAt: Int?
        public let usage: Usage?

        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
            case background
            case outputFormat = "output_format"
            case quality
            case size
            case createdAt = "created_at"
            case usage
        }

        nonisolated public struct Usage: Decodable, Sendable {
            public let inputTokens: Int?
            public let outputTokens: Int?
            public let totalTokens: Int?
            public let inputTokensDetails: InputTokensDetails?

            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
                case totalTokens = "total_tokens"
                case inputTokensDetails = "input_tokens_details"
            }

            nonisolated public struct InputTokensDetails: Decodable, Sendable {
                public let textTokens: Int?
                public let imageTokens: Int?

                enum CodingKeys: String, CodingKey {
                    case textTokens = "text_tokens"
                    case imageTokens = "image_tokens"
                }
            }
        }
    }

    private enum DiscriminatorKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DiscriminatorKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "image_generation.partial_image", "image_edit.partial_image":
            self = .partialImage(try PartialImage(from: decoder))
        case "image_generation.completed", "image_edit.completed":
            self = .completed(try Completed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown image streaming event type: \(type)")
        }
    }
}
