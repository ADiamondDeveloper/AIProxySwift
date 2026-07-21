//
//  OpenAITextToSpeechRequestBody.swift
//
//
//  Created by Daniel Aditya Istyana on 10/9/24.
//


import Foundation

/// Docstrings from
/// https://platform.openai.com/docs/api-reference/audio/createSpeech
nonisolated public struct OpenAITextToSpeechRequestBody: Encodable {

    /// The text to generate audio for. The maximum length is 4096 characters.
    public let input: String

    /// One of the available TTS models: `.tts1`, `.tts1HD` or `.gpt4oMiniTTS`
    public let model: Model

    /// The voice to use when generating the audio. Supported voices are `alloy`, `echo`, `fable`, `onyx`, `nova`, and `shimmer`.
    public let voice: Voice

    // MARK: Optional properties

    /// Control the voice of your generated audio with additional instructions. Does not work with `tts-1` or `tts-1-hd`.
    public let instructions: String?

    /// The format to audio in. Supported formats are `mp3`, `opus`, `aac`, `flac`, `wav`, and `pcm`.
    /// Default to `mp3`
    public let responseFormat: ResponseFormat?

    /// The speed of the generated audio. Select a value from 0.25 to 4.0.
    /// Default to `1.0`
    public let speed: Float?

    /// The format to stream the audio in. Pass `.sse` to receive server-sent
    /// events instead of raw audio bytes: the audio then arrives as base64
    /// deltas and a terminal `speech.audio.done` carries the token usage, which
    /// the plain audio response does not report at all.
    /// Not supported by `tts-1` / `tts-1-hd`.
    public let streamFormat: StreamFormat?

    public init(
        input: String,
        model: Model = .tts1,
        voice: OpenAITextToSpeechRequestBody.Voice,
        instructions: String? = nil,
        responseFormat: OpenAITextToSpeechRequestBody.ResponseFormat? = .mp3,
        speed: Float? = 1.0,
        streamFormat: OpenAITextToSpeechRequestBody.StreamFormat? = nil
    ) {
        self.input = input
        self.model = model
        self.voice = voice
        self.instructions = instructions
        self.responseFormat = responseFormat
        self.speed = speed
        self.streamFormat = streamFormat
    }
    
    private enum CodingKeys: String, CodingKey {
        case input
        case model
        case voice

        // Optional properties
        case instructions
        case responseFormat = "response_format"
        case speed
        case streamFormat = "stream_format"
    }

    /// How the response is delivered.
    nonisolated public enum StreamFormat: String, Encodable, Sendable {
        /// Raw audio bytes (the default). Reports no usage.
        case audio
        /// Server-sent events: base64 audio deltas plus a terminal
        /// `speech.audio.done` carrying token usage.
        case sse
    }
}

// MARK: -
extension OpenAITextToSpeechRequestBody {
    nonisolated public enum Model: String, Encodable, Sendable {
        case gpt4oMiniTTS = "gpt-4o-mini-tts"
        case tts1 = "tts-1"
        case tts1HD = "tts-1-hd"
    }
}

// MARK: -
extension OpenAITextToSpeechRequestBody {
    nonisolated public enum ResponseFormat: String, Encodable, Sendable {
        case aac
        case flac
        case mp3
        case pcm
        case opus
        case wav
    }
}

// MARK: -
extension OpenAITextToSpeechRequestBody {
    nonisolated public enum Voice: String, Encodable, Sendable, CaseIterable {
        case alloy
        case ash
        case ballad
        case coral
        case echo
        case fable
        case onyx
        case nova
        case sage
        case shimmer
    }
}
