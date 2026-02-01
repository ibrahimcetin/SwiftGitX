import Testing

extension Testing.Tag {
    // Categories
    @Tag static var collection: Self
    @Tag static var error: Self
    @Tag static var model: Self
    @Tag static var operation: Self
    @Tag static var repository: Self
    @Tag static var runtime: Self

    // Operations
    @Tag static var add: Self
    @Tag static var clone: Self
    @Tag static var commit: Self
    @Tag static var diff: Self
    @Tag static var fetch: Self
    @Tag static var log: Self
    @Tag static var merge: Self
    @Tag static var patch: Self
    @Tag static var pull: Self
    @Tag static var push: Self
    @Tag static var reset: Self
    @Tag static var restore: Self
    @Tag static var revert: Self
    @Tag static var show: Self
    @Tag static var status: Self
    @Tag static var `switch`: Self

    // Collections
    @Tag static var branch: Self
    @Tag static var config: Self
    @Tag static var index: Self
    @Tag static var reference: Self
    @Tag static var remote: Self
    @Tag static var stash: Self
    @Tag static var tag: Self

    // Models
    @Tag static var oid: Self
    @Tag static var signature: Self
}
