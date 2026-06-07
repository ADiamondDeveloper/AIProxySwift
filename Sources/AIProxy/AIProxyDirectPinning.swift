//
//  AIProxyDirectPinning.swift
//  AIProxy
//
//  Optional certificate (public-key) pinning for *DirectService(baseURL:) calls.
//  The proxied (api.aiproxy.com) path is pinned by AIProxyCertificatePinningDelegate;
//  Direct services talk to a caller-supplied baseURL, so the caller decides which
//  server public keys to trust. Set `AIProxyDirectPinning.publicKeys` at startup
//  to enable pinning for your own backend; leave it empty (default) for no pinning.
//
//  Each entry is the raw `SecKeyCopyExternalRepresentation` of a server cert's
//  public key (same format AIProxyCertificatePinningDelegate compares against).
//

import Foundation

nonisolated public enum AIProxyDirectPinning {

    nonisolated(unsafe) private static var _publicKeys: [Data] = []
    nonisolated(unsafe) private static var _enforced: Bool = false
    private static let queue = DispatchQueue(
        label: "com.aiproxy.directPinning", attributes: .concurrent
    )

    /// Trusted server public keys for Direct services. Set current + at least
    /// one backup so cert rotation can't brick the app. Each entry is the raw
    /// `SecKeyCopyExternalRepresentation` of a server cert's public key.
    public static var publicKeys: [Data] {
        get { queue.sync { _publicKeys } }
        // SYNCHRONOUS barrier write: the value is visible the instant the setter
        // returns, so a request racing startup can't read a stale empty set and
        // silently skip pinning.
        set { queue.sync(flags: .barrier) { _publicKeys = newValue } }
    }

    /// When true, a server-trust challenge with no matching pin is REJECTED
    /// (fail-closed) instead of falling back to default trust. Set this together
    /// with `publicKeys` so an empty/misconfigured pin set can't silently
    /// disable pinning while the caller believes it's on.
    public static var enforced: Bool {
        get { queue.sync { _enforced } }
        set { queue.sync(flags: .barrier) { _enforced = newValue } }
    }

    static var isActive: Bool { enforced || !publicKeys.isEmpty }
}
