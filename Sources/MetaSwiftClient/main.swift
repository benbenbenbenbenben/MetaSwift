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

@with(Abc.Trait)
struct SomethingThatHasAbc {
    init(){
        self.abc.myMethod()
    }
}

let somethingThatHasAbc = SomethingThatHasAbc()
if let abcFromSomethingWithAbc = Abc.init(from: somethingThatHasAbc) as Abc {
    print("somethingThatHasAbc conforms to WithTrait, somethingThatHasAbc has property abc, abc.abc = \(abcFromSomethingWithAbc.abc)")
} else {
    print("somethingThatHasAbc does NOT conform to WithTrait")
}