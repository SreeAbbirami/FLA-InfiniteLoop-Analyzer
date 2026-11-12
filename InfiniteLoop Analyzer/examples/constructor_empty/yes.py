class EmptyClass:
    def __init__(self):
        pass

class AnotherEmptyClass:
    def __init__(self, param1, param2):
        pass

class PartiallyEmptyClass:
    def __init__(self):
        pass
    
    def method(self):
        return "Hello"

class NestedEmptyClass:
    class InnerClass:
        def __init__(self):
            pass