def function_without_return():
    x = 10
    y = 20
    u = x + y  # Missing return statement

def function_with_conditional_return(x):
    if x > 0:
        return x
    # Missing return for the else case

def function_with_early_return():
    return 42
    print("This will never execute")

class TestClass:
    def method_with_return(self):
        return "Hello"
    
    def method_without_return(self):
        print("No return here")