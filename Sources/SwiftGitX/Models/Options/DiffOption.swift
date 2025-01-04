public struct DiffOption: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let workingTree = DiffOption(rawValue: 1 << 0)
    public static let index = DiffOption(rawValue: 1 << 1)
}

extension DiffOption: Sendable {}
