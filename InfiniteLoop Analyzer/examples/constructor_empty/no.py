class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age

class SimpleClass:
    def __init__(self):
        self.value = 0

class ComplexClass:
    def __init__(self, **kwargs):
        self.data = kwargs
        self.initialized = True

class ChildClass(Person):
    def __init__(self, name, age, grade):
        super().__init__(name, age)
        self.grade = grade

class DefaultClass:
    def __init__(self, value=None):
        self.value = value if value is not None else "default"
        
class ParentClass:
    def __init__(self, name):
        self.name = name
    
# Okay because parent class have non-empty __init__
class ChildClass(ParentClass):
    def __init__(self):
        super().__init__()
        pass