// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) =
    #externalMacro(module: "MetaSwiftMacros", type: "StringifyMacro")

// A macro that can be used to define traits or other metadata.
@attached(peer, names: prefixed(With), named(MetaSwiftTrait))
@attached(extension, names: arbitrary, conformances: MetaSwiftTrait)
public macro trait() = #externalMacro(module: "MetaSwiftMacros", type: "TraitMacro")

public enum TraitIdentity: CustomStringConvertible {
    case of(String)
    public var description:String {
        get {
            // return the name of the trait as a string
            switch self {
            case .of(let name):
                return name
            }
        }
    }
}

public protocol MetaSwiftTrait {
    static var Trait: TraitIdentity { get }
    init()
    init(_ withTrait: WithTrait) throws
}

public protocol WithTrait : Sendable {}

@attached(member, names: arbitrary)
@attached(extension, conformances: WithTrait)
public macro with(_ trait: TraitIdentity) =
    #externalMacro(module: "MetaSwiftMacros", type: "WithMacro")

/// A macro that produces the name of a type as a string. For example,
///     #nameof(Int.self)
/// produces the string `"Int"`.
@freestanding(expression)
public macro nameof<T>(_ type: T.Type) -> String =
    #externalMacro(module: "MetaSwiftMacros", type: "NameOfMacro")