//
//  DirectURLSessionDataDelegate.swift
//  AIProxy
//
//  Created by Lou Zell on 11/24/25.
//

import Foundation

nonisolated final class DirectURLSessionDataDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    /// Why is this needed?
    /// For some streaming use cases, we don't want to always consume textual lines through the modern `asyncBytes.lines` helper.
    /// Some use cases require vending data as it arrives off the wire, such as streaming audio.
    /// Unfortunately, modern async/await URLSession APIs don't provide this functionality out of the box.
    /// This closure acts as a bridge to the legacy delegate-based URLSession partial data vendor.
    nonisolated(unsafe) private var _bridges: [URLSessionDataTask: URLSessionDataTaskBridge] = [:]
    var bridges: [URLSessionDataTask: URLSessionDataTaskBridge] {
        get {
            ProtectedPropertyQueue.urlSessionBridges.sync { self._bridges }
        }
    }

    func addBridge(for dataTask: URLSessionDataTask, box: URLSessionDataTaskBridge) {
        ProtectedPropertyQueue.urlSessionBridges.async(flags: .barrier) {
            self._bridges[dataTask] = box
        }
    }

    func removeBridge(for dataTask: URLSessionDataTask) {
        ProtectedPropertyQueue.urlSessionBridges.async(flags: .barrier) {
            self._bridges.removeValue(forKey: dataTask)
        }
    }

    // MARK: - URLSessionTaskDelegate
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let dataTask = task as? URLSessionDataTask else {
            return
        }
        Task { @AIProxyActor in
            for completeCallback in self.bridges[dataTask]?.onComplete ?? [] {
                completeCallback(error)
            }
            self.removeBridge(for: dataTask)
        }
    }

    // MARK: - URLSessionDataDelegate conformance
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @Sendable @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        Task { @AIProxyActor in
            for responseCallback in self.bridges[dataTask]?.onResponse ?? [] {
                responseCallback(response)
            }
        }
        completionHandler(.allow)
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        Task { @AIProxyActor in
            for dataCallback in self.bridges[dataTask]?.onData ?? [] {
                dataCallback(data)
            }
        }
    }

    // MARK: - Optional public-key pinning
    // Off unless `AIProxyDirectPinning.publicKeys` is set (default TLS trust
    // otherwise — so unconfigured callers and localhost dev keep working).

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return Self.answerChallenge(challenge)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        return Self.answerChallenge(challenge)
    }

    private static func answerChallenge(
        _ challenge: URLAuthenticationChallenge
    ) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        // Pinning entirely off → default trust.
        guard AIProxyDirectPinning.isActive else {
            return (.performDefaultHandling, nil)
        }
        // Only server-trust challenges are pinned; others → default handling.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let secTrust = challenge.protectionSpace.serverTrust else {
            return (.performDefaultHandling, nil)
        }
        // Match ANY cert in the presented chain (leaf / intermediate / root) so a
        // pinned stable intermediate/root survives a leaf rotation.
        let serverKeys = serverPublicKeys(secTrust)
        let pins = AIProxyDirectPinning.publicKeys
        // enforced with an empty/non-matching pin set → cancel (fail-closed).
        return serverKeys.contains(where: pins.contains)
            ? (.useCredential, URLCredential(trust: secTrust))
            : (.cancelAuthenticationChallenge, nil)
    }

    private static func serverPublicKeys(_ secTrust: SecTrust) -> [Data] {
        let chain: [SecCertificate]
        if #available(macOS 12.0, iOS 15.0, *) {
            chain = (SecTrustCopyCertificateChain(secTrust) as? [SecCertificate]) ?? []
        } else {
            var certs: [SecCertificate] = []
            let count = SecTrustGetCertificateCount(secTrust)
            for i in 0..<count {
                if let c = SecTrustGetCertificateAtIndex(secTrust, i) { certs.append(c) }
            }
            chain = certs
        }
        return chain.compactMap { cert in
            guard let key = SecCertificateCopyKey(cert) else { return nil }
            return SecKeyCopyExternalRepresentation(key, nil) as Data?
        }
    }
}
