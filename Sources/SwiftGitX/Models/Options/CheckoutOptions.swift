import libgit2

// Only internal usage for now
struct CheckoutOptions: Sendable {
    /// The checkout strategy to use. Default is `.safe`.
    let strategy: CheckoutStrategy

    /// The paths to checkout. If empty, all paths will be checked out.
    let paths: [String]

    init(strategy: CheckoutStrategy = .safe, paths: [String] = []) {
        self.strategy = strategy
        self.paths = paths
    }

    func withGitCheckoutOptions<T>(
        _ body: (git_checkout_options) throws(SwiftGitXError) -> T
    ) throws(SwiftGitXError) -> T {
        // Initialize the options with the default values
        var options = git_checkout_options()

        try git {
            git_checkout_options_init(&options, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
        }

        // Set the checkout strategies
        options.checkout_strategy = strategy.rawValue

        // Set the paths
        var checkoutPaths = paths.gitStrArray
        defer { git_strarray_free(&checkoutPaths) }

        options.paths = checkoutPaths

        return try body(options)
    }
}

struct CheckoutStrategy: OptionSet {
    // MARK: - Properties

    public let rawValue: UInt32

    // MARK: - Initializers

    init(_ strategy: git_checkout_strategy_t) {
        rawValue = strategy.rawValue
    }

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    // MARK: - Options

    public static let none = CheckoutStrategy(GIT_CHECKOUT_NONE)

    public static let safe = CheckoutStrategy(GIT_CHECKOUT_SAFE)

    public static let force = CheckoutStrategy(GIT_CHECKOUT_FORCE)

    public static let recreateMissing = CheckoutStrategy(GIT_CHECKOUT_RECREATE_MISSING)

    public static let allowConflicts = CheckoutStrategy(GIT_CHECKOUT_ALLOW_CONFLICTS)

    public static let removeUntracked = CheckoutStrategy(GIT_CHECKOUT_REMOVE_UNTRACKED)

    public static let removeIgnored = CheckoutStrategy(GIT_CHECKOUT_REMOVE_IGNORED)

    public static let updateOnly = CheckoutStrategy(GIT_CHECKOUT_UPDATE_ONLY)

    public static let notUpdateIndex = CheckoutStrategy(GIT_CHECKOUT_DONT_UPDATE_INDEX)

    public static let noRefresh = CheckoutStrategy(GIT_CHECKOUT_NO_REFRESH)

    public static let skipUnmerged = CheckoutStrategy(GIT_CHECKOUT_SKIP_UNMERGED)

    public static let useOurs = CheckoutStrategy(GIT_CHECKOUT_USE_OURS)

    public static let useTheirs = CheckoutStrategy(GIT_CHECKOUT_USE_THEIRS)

    public static let disablePathSpecMatch = CheckoutStrategy(GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH)

    public static let skipLockedDirectories = CheckoutStrategy(GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES)

    // TODO: Add remaining options
}
