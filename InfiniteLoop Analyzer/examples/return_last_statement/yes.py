def simple_function():
    x = 10
    y = 20
    return x + y

def conditional_function(x):
    if x > 0:
        result = "Positive"
    else:
        result = "Non-positive"
    return result

def complex_function(a, b):
    for i in range(a):
        if i == b:
            break
    return i

def empty_function():
    return None

class TestClass:
    def test_method(self):
        return "Success"