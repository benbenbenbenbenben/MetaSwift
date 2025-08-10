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
struct Fooer {
    let abc: Int
    func myMethod() {
        print("Hello, World!")
    }
    init() {
        abc = 42
    }
}

@with(Fooer.Trait)
struct SomethingThatHasFoo {
    init(){
        self.fooer.myMethod()
    }
}

let aaa = SomethingThatHasFoo()
if let withFooer = Fooer(from: aaa) {
    print("aaa conforms to WithTrait, aaa has property fooer, fooer.abc = \(withFooer.abc)")
} else {
    print("aaa does NOT conform to WithTrait")
}
// TODO: test if we can treat aaa as WithFooer protocol