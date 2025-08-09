import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct NameOfMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        // This macro returns the name of the type (Type.self) as a string.
        // For example, #nameof(Int.self) expands to "Int".
        guard let name = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        // name will end .self, so we need to remove it.
        let typeName = name.description.dropLast(5)

        return .init(stringLiteral: "\"\(typeName)\"")
    }
}

// TODO: any trait type should conform to a default init()
// TODO: we should add an init that does a cast or throw to the trait type i.e. let thingAsTrait = try Trait(thing)
public struct TraitMacro: PeerMacro, ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError("TraitMacro can only be applied to a struct")
        }
        let typeName = structDecl.name.text

        // Check for parameterless initializer
        let hasDefaultInit = structDecl.memberBlock.members.contains { member in
            if let initDecl = member.decl.as(InitializerDeclSyntax.self) {
                // Check if init has no parameters and is not failable
                return initDecl.signature.input.parameterList.isEmpty && initDecl.optionalMark == nil
            }
            return false
        }

        if !hasDefaultInit {
            throw MacroError("Struct \(typeName) must have an init() with no parameters to be used as a trait")
        }

        let decl: DeclSyntax = """
            extension \(raw: typeName) : MetaSwift.MetaSwiftTrait {
                public static var Trait: TraitIdentity {get{
                    return .of("\(raw:typeName)")
                }}
            }
            """
        guard let extensionDecl = ExtensionDeclSyntax(decl) else {
            throw MacroError("Failed to create extension declaration")
        }
        return [extensionDecl]
    }

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    )
        throws -> [SwiftSyntax.DeclSyntax]
    {
        // This macro is attached to a type and creates a protocol with a single property.
        // The protocol name is the type name prefixed with "With".
        // The property name is the type name with the first letter lowercased.
        guard let typeName = declaration.as(StructDeclSyntax.self)?.name.text else {
            throw MacroError("TraitMacro can only be applied to a struct")
        }

        // lowercase the first letter to use it as a variable name.
        let variableName = typeName.prefix(1).lowercased() + typeName.dropFirst()

        let decl: DeclSyntax = """
            protocol With\(raw: typeName) {
                var \(raw: variableName): \(raw: typeName) { get }
            }
            """
        return [
            decl
        ]
    }

}

public struct WithTraitMacro: MemberMacro {
    // TODO: re-enable extension macro to add With<TraitName> protocol...

    // public static func expansion(
    //     of node: SwiftSyntax.AttributeSyntax,
    //     attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    //     providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    //     conformingTo protocols: [SwiftSyntax.TypeSyntax],
    //     in context: some SwiftSyntaxMacros.MacroExpansionContext
    // ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    //     // Can only be applied to a struct
    //     guard let structDecl = declaration.as(StructDeclSyntax.self) else {
    //         throw MacroError("WithTraitMacro can only be applied to a struct")
    //     }
    //     // Get the trait name from the attribute argument
    //     guard let stringLiteralExpr = node.argument?.as(StringLiteralExprSyntax.self),
    //         let firstSegment = stringLiteralExpr.segments.first?.as(StringSegmentSyntax.self)
    //     else {
    //         throw MacroError("WithTraitMacro requires a trait name")
    //     }
    //     let traitName = firstSegment.content.text
    //     // Create the extension declaration
    //     let traitType = "MetaSwift.MetaSwiftTrait.\(traitName)"
    //     let decl: DeclSyntax = """
    //         extension \(raw: structDecl.name.text) : \(raw: traitType) {
    //             var \(raw: traitName.lowercased()): \(raw: structDecl.name.text) {
    //                 return self
    //             }
    //         }
    //         """
    //     guard let extensionDecl = ExtensionDeclSyntax(decl) else {
    //         throw MacroError("Failed to create extension declaration")
    //     }
    //     return [extensionDecl]
    // }
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // this macro is call like @withtrait(MyTrait.Trait)
        // we need to stringify the reference expression "MyTrait.Trait" and 
        // create a member variable with the name of the trait.
        
        guard var traitTypeName = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.description else {
            throw MacroError("withtrait macro requires a trait argument")
        }

        // ensure traitTypeName ends with .Trait
        guard traitTypeName.description.hasSuffix(".Trait") else {
            throw MacroError("withtrait macro requires a trait argument ending with .Trait")
        }

        // remove the .Trait suffix
        traitTypeName = "\(traitTypeName.dropLast(6))"

        // get trait type name with the first letter lowercased
        let traitName = traitTypeName.prefix(1).lowercased() + traitTypeName.dropFirst()

        let memDecl:DeclSyntax = """
        let \(raw: traitName): \(raw: traitTypeName) = \(raw: traitTypeName)()
        """
        return [memDecl]
    }
}

struct MacroError: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var description: String {
        "MacroError: \(message)"
    }
}

@main
struct MetaSwiftPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        TraitMacro.self,
        NameOfMacro.self,
        WithTraitMacro.self,
    ]
}
