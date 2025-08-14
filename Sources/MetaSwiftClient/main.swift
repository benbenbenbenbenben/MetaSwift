import MetaSwift

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

struct FooBar {
    let value: Int
}

struct FizzBuzz {
    let value: Int
    struct BuzzFizz {
        let value: Int
    }
}

protocol Foo {
    var foo: Int { get }
}

let fooBar = #nameof(FooBar.self)

print("The value \(result) was produced by the code \"\(code)\"")

print("The name of the type FooBar is \(fooBar)")

@trait()
struct Abc {
    let abc: Int
    func myMethod() {
        print("Hello, World!")
    }
    init() {
        abc = 42
    }
}

@trait()
struct Xyz {
    let xyz: Int
    init() {
        xyz = 99
    }
}

@with(Abc.Trait)
struct SomethingThatHasAbc {
    init(){
        self.abc.myMethod()
    }
}

@with(Abc.Trait, Xyz.Trait)
struct SomethingThatHasAbcAndXyz {
    init(){
        self.abc.myMethod()
        print("xyz = \(self.xyz.xyz)")
    }
}

let somethingThatHasAbc = SomethingThatHasAbc()
if let abcFromSomethingWithAbc = try? Abc(from: somethingThatHasAbc) {
    print("somethingThatHasAbc conforms to WithTrait, somethingThatHasAbc has property abc, abc.abc = \(abcFromSomethingWithAbc.abc)")
} else {
    print("somethingThatHasAbc does NOT conform to WithTrait")
}

let somethingThatHasAbcAndXyz = SomethingThatHasAbcAndXyz()
if let abcFromSomethingWithAbcAndXyz = try? Abc(from: somethingThatHasAbcAndXyz) {
    print("somethingThatHasAbcAndXyz conforms to WithTrait, somethingThatHasAbcAndXyz has property abc, abc.abc = \(abcFromSomethingWithAbcAndXyz.abc)")
} else {
    print("somethingThatHasAbcAndXyz does NOT conform to WithTrait")
}
if let xyzFromSomethingWithAbcAndXyz = try? Xyz(from: somethingThatHasAbcAndXyz) {
    print("somethingThatHasAbcAndXyz conforms to WithTrait, somethingThatHasAbcAndXyz has property xyz, xyz.xyz = \(xyzFromSomethingWithAbcAndXyz.xyz)")
} else {
    print("somethingThatHasAbcAndXyz does NOT conform to WithTrait")
}