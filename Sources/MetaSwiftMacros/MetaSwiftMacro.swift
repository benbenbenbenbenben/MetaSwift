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

// TODO: we should add an init that does a cast or throw to the trait type i.e. let thingAsTrait = try Trait(thing)
public struct TraitMacro: ExtensionMacro {
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
                return initDecl.signature.parameterClause.parameters.isEmpty && initDecl.optionalMark == nil
            }
            return false
        }

        if !hasDefaultInit {
            throw MacroError("Struct \(typeName) must have an init() with no parameters to be used as a trait")
        }

        // Get the trait name, which is the first letter lowercased
        let traitName = typeName
        let traitNameLowercased = traitName.prefix(1).lowercased() + traitName.dropFirst()

        let decl: DeclSyntax = """
            extension \(raw: typeName) : MetaSwift.MetaSwiftTrait {
                struct \(raw: traitName)Error: Error, CustomStringConvertible {
                    let message: String
                    init(_ message: String) {
                        self.message = message
                    }
                    public var description: String {
                        "TraitError: \\(message)"
                    }
                }
                public static var Trait: TraitIdentity {get{
                    return .of("\(raw:typeName)")
                }}
                public init(from: WithTrait) throws {
                    // lookup property named \(raw: traitNameLowercased) in from
                    guard let traitProp = from[dynamicMember: "\(raw: traitNameLowercased)"] else {
                        throw \(raw: traitName)Error("Failed to find property \(raw: traitNameLowercased) in from")
                    }
                    guard let value = traitProp as? \(raw: traitName) else {
                        throw \(raw: traitName)Error("Property \(raw: traitNameLowercased) is not of type \(raw: traitName)")
                    }
                    self = value
                }
            }
            """
        guard let extensionDecl = ExtensionDeclSyntax(decl) else {
            throw MacroError("Failed to create extension declaration")
        }
        return [extensionDecl]
    }


}

public struct WithMacro: MemberMacro, ExtensionMacro {
    // TODO: re-enable extension macro to add With<TraitName> protocol...

   public static func expansion(
       of node: SwiftSyntax.AttributeSyntax,
       attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
       providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
       conformingTo protocols: [SwiftSyntax.TypeSyntax],
       in context: some SwiftSyntaxMacros.MacroExpansionContext
   ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
       // Can only be applied to a struct
       guard let structDecl = declaration.as(StructDeclSyntax.self) else {
           throw MacroError("WithMacro can only be applied to a struct")
       }
       guard var traitTypeName = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.description else {
            throw MacroError("with macro requires a trait argument")
        }

        // ensure traitTypeName ends with .Trait
        guard traitTypeName.description.hasSuffix(".Trait") else {
            throw MacroError("with macro requires a trait argument ending with .Trait")
        }

        // remove the .Trait suffix
        traitTypeName = "\(traitTypeName.dropLast(6))"
       let decl: DeclSyntax = """
           extension \(raw: structDecl.name.text): WithTrait {}
           """
       guard let extensionDecl = ExtensionDeclSyntax(decl) else {
           throw MacroError("Failed to create extension declaration")
       }
       return [extensionDecl]
   }
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // this macro is call like @with(MyTrait.Trait)
        // we need to stringify the reference expression "MyTrait.Trait" and
        // create a member variable with the name of the trait.
        
        guard var traitTypeName = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.description else {
            throw MacroError("with macro requires a trait argument")
        }

        // ensure traitTypeName ends with .Trait
        guard traitTypeName.description.hasSuffix(".Trait") else {
            throw MacroError("with macro requires a trait argument ending with .Trait")
        }

        // remove the .Trait suffix
        traitTypeName = "\(traitTypeName.dropLast(6))"

        // get trait type name with the first letter lowercased
        let traitName = traitTypeName.prefix(1).lowercased() + traitTypeName.dropFirst()

        let memDecl:DeclSyntax = """
        let \(raw: traitName): \(raw: traitTypeName) = \(raw: traitTypeName)()
        subscript(dynamicMember member: String) -> Any? {
            // this allows us to access the trait property as a dynamic member
            // e.g. let abc = somethingWithTrait.abc
            if member == "\(raw: traitName)" {
                return self.\(raw: traitName)
            }
            return nil
        }
        """
        return [memDecl]
    }
}

public struct MacroError: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var description: String {
        "MacroError: \(message)"
    }
}

@main
struct MetaSwiftPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        TraitMacro.self,
        NameOfMacro.self,
        WithMacro.self,
    ]
}
