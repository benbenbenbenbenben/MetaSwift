# MetaSwift

Metaprogramming utilities for Swift using Swift Macros. Provides freestanding and attached macros to simplify reflection-like patterns and trait-style composition.

- Package manifest: [Package.swift](Package.swift)
- Public macro declarations: [stringify<T>()](Sources/MetaSwift/MetaSwift.swift:11), [trait()](Sources/MetaSwift/MetaSwift.swift:17), [with(_:) ](Sources/MetaSwift/MetaSwift.swift:42), [nameof<T>()](Sources/MetaSwift/MetaSwift.swift:49)
- Macro implementations: [Sources/MetaSwiftMacros/MetaSwiftMacro.swift](Sources/MetaSwiftMacros/MetaSwiftMacro.swift)

## Features

- [stringify<T>()](Sources/MetaSwift/MetaSwift.swift:11): Expand an expression into a tuple of its value and source text.
- [nameof<T>()](Sources/MetaSwift/MetaSwift.swift:49): Produce a type name as a string from `Type.self`.
- [trait()](Sources/MetaSwift/MetaSwift.swift:17): Attach to a `struct` to declare it as a MetaSwift trait; generates conformance and helpers. Requires a parameterless `init()`.
- [with(_:) ](Sources/MetaSwift/MetaSwift.swift:42): Attach to a `struct` with a `TraitIdentity` to inject a trait instance as a stored property and make the type conform to `WithTrait`.

## Requirements

- Swift tools: 6.1 (per [Package.swift](Package.swift))
- Platforms: macOS 15+, Mac Catalyst 15+ (per [Package.swift](Package.swift))
- Dependency: `swift-syntax` (from `601.0.0-latest`)

## Installation

Add MetaSwift to your package dependencies and targets.

1) In your `Package.swift`:
- Add the package dependency
- Add `"MetaSwift"` to your target dependencies

2) Products and targets are defined in [Package.swift](Package.swift):
- Library: `MetaSwift`
- Executable: `MetaSwiftClient`
- Macro target: `MetaSwiftMacros`

## Usage

Examples are demonstrated in the client executable: [Sources/MetaSwiftClient/main.swift](Sources/MetaSwiftClient/main.swift)

- stringify an expression
  - API: [stringify<T>()](Sources/MetaSwift/MetaSwift.swift:11)
  - Example site: [main.swift:6](Sources/MetaSwiftClient/main.swift:6)

- get a type name
  - API: [nameof<T>()](Sources/MetaSwift/MetaSwift.swift:49)
  - Example site: [main.swift:23](Sources/MetaSwiftClient/main.swift:23)

- declare a trait
  - API (attached): [trait()](Sources/MetaSwift/MetaSwift.swift:17)
  - Example site: [main.swift:29](Sources/MetaSwiftClient/main.swift:29)

- consume a trait with `with`
  - API (attached): [with(_:) ](Sources/MetaSwift/MetaSwift.swift:42)
  - Example site: [main.swift:40](Sources/MetaSwiftClient/main.swift:40)

### Behavior details

- [trait()](Sources/MetaSwift/MetaSwift.swift:17) attaches an extension implementing `MetaSwiftTrait`:
  - Requires a parameterless initializer; enforced by macro implementation ([MetaSwiftMacro.swift:60](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:60)–[MetaSwiftMacro.swift:71](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:71))
  - Synthesizes `static var Trait: TraitIdentity` and `init(from: WithTrait)` that extracts the trait instance via dynamic member lookup ([MetaSwiftMacro.swift:77](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:77)–[MetaSwiftMacro.swift:101](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:101))

- [with(_:) ](Sources/MetaSwift/MetaSwift.swift:42) attaches:
  - `WithTrait` conformance and a stored property whose name is the lowercased trait type (e.g. `Abc` → `abc`)
  - A dynamic member subscript to expose the trait instance by name ([MetaSwiftMacro.swift:145](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:145)–[MetaSwiftMacro.swift:181](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:181))

## Build and Run

- Build the library and client:
  - `swift build`
- Run the demo client:
  - `swift run MetaSwiftClient`

The client demonstrates:
- [stringify<T>()](Sources/MetaSwift/MetaSwift.swift:11) at [main.swift:6](Sources/MetaSwiftClient/main.swift:6)
- [nameof<T>()](Sources/MetaSwift/MetaSwift.swift:49) at [main.swift:23](Sources/MetaSwiftClient/main.swift:23)
- [trait()](Sources/MetaSwift/MetaSwift.swift:17) at [main.swift:29](Sources/MetaSwiftClient/main.swift:29)
- [with(_:) ](Sources/MetaSwift/MetaSwift.swift:42) at [main.swift:40](Sources/MetaSwiftClient/main.swift:40)

## Testing

- Run tests: `swift test`
- Tests cover macro expansions using `SwiftSyntaxMacrosTestSupport` (see [Tests/MetaSwiftTests/MetaSwiftTests.swift](Tests/MetaSwiftTests/MetaSwiftTests.swift))

## API Reference

- Public types:
  - [TraitIdentity](Sources/MetaSwift/MetaSwift.swift:19)
  - [MetaSwiftTrait](Sources/MetaSwift/MetaSwift.swift:30)
  - [WithTrait](Sources/MetaSwift/MetaSwift.swift:36)

- Macros:
  - [stringify<T>()](Sources/MetaSwift/MetaSwift.swift:11)
  - [trait()](Sources/MetaSwift/MetaSwift.swift:17)
  - [with(_:) ](Sources/MetaSwift/MetaSwift.swift:42)
  - [nameof<T>()](Sources/MetaSwift/MetaSwift.swift:49)

## Notes and Constraints

- `@trait()` may only be attached to `struct`s and requires a non-failable `init()` with no parameters. Violations result in a `MacroError` at expansion time ([MetaSwiftMacro.swift:55](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:55)–[MetaSwiftMacro.swift:71](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:71)).
- `@with(MyTrait.Trait)` requires a `TraitIdentity` argument ending with `.Trait`; otherwise expansion throws ([MetaSwiftMacro.swift:159](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:159)–[MetaSwiftMacro.swift:166](Sources/MetaSwiftMacros/MetaSwiftMacro.swift:166)).

## License

This project is available under the terms of the [LICENSE](LICENSE).