public interface IFoo
{
    int GetAge();
    public event Event Event;
}

public class Foo : IFoo
{
    // explicit interface implementation
    int IFoo.GetAge() => 42;
    event Event IFoo.Event;
}

class Baz {
    private int Foo() => 2;
    void Run() {}
}

int TopLevelMethod() {}



