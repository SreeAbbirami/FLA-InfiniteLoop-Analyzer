class GoodClass1:
    def __init__(self):
        self.value = 42
        # No return statement

class GoodClass2:
    def __init__(self, value):
        self.value = value
        # Initialization only

class GoodClass3:
    def __init__(self):
        self.name = "Instance"
        # No return statement

class Factory:
    def __init__(self, type_name):
        self.type = type_name
    
    def create(self):
        # Factory method returns object, not __init__
        if self.type == "int":
            return 0
        return ""