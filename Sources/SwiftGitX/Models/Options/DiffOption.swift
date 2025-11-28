public struct DiffOption: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let workingTree = DiffOption(rawValue: 1 << 0)
    public static let index = DiffOption(rawValue: 1 << 1)
}
