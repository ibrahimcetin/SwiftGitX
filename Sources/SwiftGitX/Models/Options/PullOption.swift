//
//  PullOption.swift
//  SwiftGitX
//

/// Options for pull operation.
public enum PullOption: Sendable {
    /// Allow fast-forward or merge (default behavior).
    case auto

    /// Only allow fast-forward, fail if not possible.
    case fastForwardOnly

    /// Always create merge commit, even if fast-forward is possible.
    case noFastForward

    /// Rebase local commits on top of remote instead of merging.
    case rebase
}
