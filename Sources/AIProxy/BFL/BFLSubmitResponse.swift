//
//  BFLSubmitResponse.swift
//  AIProxy
//
//  Created on 27.03.2026.
//

import Foundation

/// Response from BFL when submitting an image generation request.
public struct BFLSubmitResponse: Decodable, Sendable {
    /// The task ID
    public let id: String
    /// The polling URL to check for results (use this instead of constructing your own)
    public let polling_url: String?
}
