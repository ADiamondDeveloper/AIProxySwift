//
//  BFLTaskResponse.swift
//  AIProxy
//
//  Created on 27.03.2026.
//

import Foundation

/// Response from BFL when polling for task results.
public struct BFLTaskResponse: Decodable, Sendable {
    /// The task ID
    public let id: String
    /// The task status: "Pending", "Processing", "Queued", "Ready", "Failed", "Error", "Task not found"
    public let status: String
    /// The result data (only present when status is "Ready")
    public let result: ResultData?

    public struct ResultData: Decodable, Sendable {
        /// The signed URL for the generated image (valid for 10 minutes)
        public let sample: String?
    }
}
