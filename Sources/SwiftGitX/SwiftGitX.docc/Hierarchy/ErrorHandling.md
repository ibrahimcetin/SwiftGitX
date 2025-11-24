# Error Handling

Comprehensive error handling with typed throws

## Overview

SwiftGitX uses a unified `SwiftGitXError` type for all Git operations, leveraging Swift's typed throws for type-safe error handling. Every error provides detailed context including what went wrong (``SwiftGitXError/Code-swift.enum``), where it originated (``SwiftGitXError/Category-swift.enum``), which operation failed (``SwiftGitXError/Operation-swift.struct``), and a human-readable message.

All throwing functions in SwiftGitX use `throws(SwiftGitXError)`, enabling compile-time error type checking and eliminating the need for generic error handling.

## Topics

### Error Type

- ``SwiftGitXError``

### Error Properties

- ``SwiftGitXError/code``
- ``SwiftGitXError/operation``
- ``SwiftGitXError/category``
- ``SwiftGitXError/message``

### Error Classification

- ``SwiftGitXError/Code-swift.enum``
- ``SwiftGitXError/Category-swift.enum``
- ``SwiftGitXError/Operation-swift.struct``

### Convenience Properties

- ``SwiftGitXError/Code-swift.enum/isNotFound``
- ``SwiftGitXError/Code-swift.enum/isConflict``
- ``SwiftGitXError/Code-swift.enum/isAuth``
- ``SwiftGitXError/Code-swift.enum/isLocked``
- ``SwiftGitXError/Code-swift.enum/requiresForce``
- ``SwiftGitXError/Code-swift.enum/hasUncommittedChanges``
