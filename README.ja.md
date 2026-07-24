# SwiftGitX
<p align="center"><a href="./README.md">English</a> · <a href="./README.zh-CN.md">简体中文</a> · <a href="./README.ja.md">日本語</a></p>
[![CI](https://github.com/ibrahimcetin/SwiftGitX/actions/workflows/swift.yml/badge.svg)](https://github.com/ibrahimcetin/SwiftGitX/actions/workflows/swift.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fibrahimcetin%2FSwiftGitX%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fibrahimcetin%2FSwiftGitX%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX)

SwiftGitX へようこそ！🎉

SwiftGitX は [libgit2](https://libgit2.org) のモダンな Swift ラッパーです。Swift から Git を簡単かつ効率的に扱えるよう設計されています。また、[Swift Package Manager](https://github.com/swiftlang/swift-package-manager) を完全にサポートし、外部依存関係はありません。

```swift
let url = URL(string: "https://github.com/ibrahimcetin/SwiftGitX.git")!
let repository = try await Repository.clone(from: url, to: URL(string: "/path/to/clone")!)

let latestCommit = try repository.HEAD.target as? Commit

let main = try repository.branch.get(named: "main")
let feature = try repository.branch.create(named: "feature", from: main)
try repository.switch(to: feature)
```

## SwiftGitX を選ぶ理由

SwiftGitX には次の特長があります。

- **Swift Concurrency のサポート**：async/await を活用し、滑らかでノンブロッキングな Git 操作を実現します。
- **エラーを送出する関数**：Swift のエラー処理を使ってエラーを適切に処理できます。
- **SPM の完全サポート**：SwiftGitX をプロジェクトへ簡単に組み込めます。
- **直感的な設計**：Git のコマンドラインインターフェースに似た使いやすい API のため、容易に学習して利用できます。
- **単なるバインディングではないラッパー**：SwiftGitX は、低レベルの C 関数や型を公開せず、完全な Swift 体験を提供します。モダンな Git コマンドも含まれており、他のライブラリより多くの機能を利用できます。

## SwiftGitX をプロジェクトに追加する

SwiftGitX をプロジェクトに追加するだけで利用を開始できます。

1. File > Add Package Dependencies...
2. https://github.com/ibrahimcetin/SwiftGitX.git を入力します。
3. "Up to Next Major" を選択し、"0.1.0" を指定します。

または、`Package.swift` ファイルに SwiftGitX を追加します。

```swift
dependencies: [
    .package(url: "https://github.com/ibrahimcetin/SwiftGitX.git", from: "0.1.0"),
]
```

## ドキュメント

`releases` および `main` のドキュメントはこちらで参照できます。

* [0.x.x](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX/~/documentation/SwiftGitX)
* [`main`](https://swiftpackageindex.com/ibrahimcetin/SwiftGitX/main/documentation/SwiftGitX)

## ビルドとテスト

SwiftGitX は簡単にビルドおよびテストできます。必要なのは Swift のみで、追加のシステム依存関係はありません。
SwiftGitX をビルドするには、次のコマンドを実行します。
```bash
swift build
```
SwiftGitX をテストするには、次のコマンドを実行します。
```bash
swift test
```

## コントリビューション

コントリビューションを歓迎します！バグ報告、機能リクエスト、ドキュメントの改善、テストの追加など、どのような形の協力にも感謝します。

**開発者の方へ**：コントリビューションの際は、プロジェクトの堅牢性と充実したドキュメントを保つため、適切なテストとドキュメントを追加してください。

---

SwiftGitX をプロジェクトに採用することをご検討いただき、ありがとうございます。これを使って何が作られるのか楽しみにしています！😊

---

さらに調整したい点があれば、具体的にお知らせください！🚀
