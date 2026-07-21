//
//  OpenAITextToSpeechStreamingEventTests.swift
//  AIProxyTests
//

import Foundation
import Testing
@testable import AIProxy

struct OpenAITextToSpeechStreamingEventTests {

    @Test
    func audioDeltaIsDecodableAndBase64Decodes() throws {
        let event = try decode(#"{"type":"speech.audio.delta","audio":"aGVsbG8="}"#)

        guard case .audioDelta(let payload) = event else {
            Issue.record("Expected audioDelta")
            return
        }
        #expect(payload.audio == "aGVsbG8=")
        #expect(payload.audioData == "hello".data(using: .utf8))
    }

    @Test
    func audioDeltaWithInvalidBase64YieldsNilRatherThanThrowing() throws {
        // A malformed payload must not blow up the stream mid-playback.
        let event = try decode(#"{"type":"speech.audio.delta","audio":"!!!not-base64!!!"}"#)

        guard case .audioDelta(let payload) = event else {
            Issue.record("Expected audioDelta")
            return
        }
        #expect(payload.audioData == nil)
    }

    /// The whole reason this stream exists: the plain audio response reports no
    /// usage, so these counts are the only way to know what a synthesis cost.
    @Test
    func audioDoneCarriesTokenUsage() throws {
        let event = try decode(
            #"{"type":"speech.audio.done","usage":{"input_tokens":14,"output_tokens":101,"total_tokens":115}}"#
        )

        guard case .audioDone(let payload) = event else {
            Issue.record("Expected audioDone")
            return
        }
        #expect(payload.usage?.inputTokens == 14)
        #expect(payload.usage?.outputTokens == 101)
        #expect(payload.usage?.totalTokens == 115)
    }

    @Test
    func audioDoneDecodesInputTokenDetails() throws {
        let event = try decode(
            #"{"type":"speech.audio.done","usage":{"input_tokens":119,"output_tokens":77,"total_tokens":196,"input_token_details":{"text_tokens":18,"audio_tokens":101}}}"#
        )

        guard case .audioDone(let payload) = event else {
            Issue.record("Expected audioDone")
            return
        }
        #expect(payload.usage?.inputTokenDetails?.textTokens == 18)
        #expect(payload.usage?.inputTokenDetails?.audioTokens == 101)
    }

    @Test
    func audioDoneWithoutUsageIsStillDecodable() throws {
        let event = try decode(#"{"type":"speech.audio.done"}"#)

        guard case .audioDone(let payload) = event else {
            Issue.record("Expected audioDone")
            return
        }
        #expect(payload.usage == nil)
    }

    @Test
    func unknownEventTypeIsFutureProofed() throws {
        let event = try decode(#"{"type":"speech.audio.something_new"}"#)

        guard case .futureProof = event else {
            Issue.record("Expected futureProof for an unrecognised type")
            return
        }
    }

    private func decode(_ json: String) throws -> OpenAITextToSpeechStreamingEvent {
        try JSONDecoder().decode(
            OpenAITextToSpeechStreamingEvent.self,
            from: json.data(using: .utf8)!
        )
    }
}
