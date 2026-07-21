//
//  OpenAITextToSpeechStreamingEvent.swift
//  AIProxy
//

import Foundation

/// Represents a server-sent event from the OpenAI create speech endpoint when
/// `stream_format` is `.sse`.
/// https://platform.openai.com/docs/api-reference/audio/createSpeech
///
/// The plain (non-SSE) audio response reports no usage at all, so this stream is
/// the only way to learn what a synthesis actually cost: `speech.audio.done`
/// carries the token counts the model is billed on.
nonisolated public enum OpenAITextToSpeechStreamingEvent: Decodable, Sendable {
    case audioDelta(AudioDelta)
    case audioDone(AudioDone)
    case futureProof

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "speech.audio.delta":
            self = .audioDelta(try AudioDelta(from: decoder))
        case "speech.audio.done":
            self = .audioDone(try AudioDone(from: decoder))
        default:
            logIf(.info)?.info("Received unknown OpenAI speech stream event of type \(type).")
            self = .futureProof
        }
    }
}

extension OpenAITextToSpeechStreamingEvent {
    nonisolated public struct AudioDelta: Decodable, Sendable {
        /// Base64-encoded chunk of the generated audio, in the requested
        /// `response_format`. Concatenate the decoded chunks in arrival order to
        /// reconstruct the file.
        public let audio: String

        /// The decoded bytes for this chunk, or nil if the payload wasn't valid
        /// base64. Decoding here keeps every caller from repeating it.
        public var audioData: Data? {
            Data(base64Encoded: audio)
        }

        private enum CodingKeys: String, CodingKey {
            case audio
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.audio = try container.decode(String.self, forKey: .audio)
        }
    }

    nonisolated public struct AudioDone: Decodable, Sendable {
        /// Token usage for the synthesis. `gpt-4o-mini-tts` bills text input and
        /// audio output at very different rates, so the split matters.
        public let usage: Usage?

        private enum CodingKeys: String, CodingKey {
            case usage
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.usage = try container.decodeIfPresent(Usage.self, forKey: .usage)
        }

        nonisolated public struct Usage: Decodable, Sendable {
            public let inputTokens: Int?
            public let outputTokens: Int?
            public let totalTokens: Int?
            public let inputTokenDetails: InputTokenDetails?

            private enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
                case totalTokens = "total_tokens"
                case inputTokenDetails = "input_token_details"
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.inputTokens = try container.decodeIfPresent(Int.self, forKey: .inputTokens)
                self.outputTokens = try container.decodeIfPresent(Int.self, forKey: .outputTokens)
                self.totalTokens = try container.decodeIfPresent(Int.self, forKey: .totalTokens)
                self.inputTokenDetails = try container.decodeIfPresent(
                    InputTokenDetails.self, forKey: .inputTokenDetails
                )
            }

            nonisolated public struct InputTokenDetails: Decodable, Sendable {
                public let textTokens: Int?
                public let audioTokens: Int?

                private enum CodingKeys: String, CodingKey {
                    case textTokens = "text_tokens"
                    case audioTokens = "audio_tokens"
                }

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.textTokens = try container.decodeIfPresent(Int.self, forKey: .textTokens)
                    self.audioTokens = try container.decodeIfPresent(Int.self, forKey: .audioTokens)
                }
            }
        }
    }
}
