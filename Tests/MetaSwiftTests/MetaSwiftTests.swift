import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MetaSwift

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MetaSwiftMacros)
import MetaSwiftMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "trait": TraitMacro.self,
    "nameof": NameOfMacro.self,
    // "withtrait": WithTraitMacro.self
]
#endif

final class MetaSwiftTests: XCTestCase {
    func testStringifyMacro() throws {
        #if canImport(MetaSwiftMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testStringifyMacroWithStringLiteral() throws {
        #if canImport(MetaSwiftMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testNameOfMacro() throws {
        #if canImport(MetaSwiftMacros)
        assertMacroExpansion(
            """
            #nameof(Int.self)
            """,
            expandedSource: """
            "Int"
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testTraitMacro() throws {
        #if canImport(MetaSwiftMacros)
        assertMacroExpansion(
            """
            @trait()
            struct MyTrait {
                func myMethod() {
                    print("Hello, World!")
                }
            }
            """,
            expandedSource: """
            struct MyTrait {
                func myMethod() {
                    print("Hello, World!")
                }
            }
            protocol WithMyTrait {
                var myTrait: MyTrait { get }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
