class BadClass1:
    def __init__(self):
        self.value = 42
        return self

class BadClass2:
    def __init__(self):
        self.name = "Instance"
        return BadClass2()  # Returning new instance

# TODO - Deal with this (Condition Structure)
class BadClass3:
    def __init__(self, value):
        self.value = value
        if value > 0:
            return self
        else:
            return BadClass3(10)

# TODO - Deal with this (Condition Structure)     
class BadClass4:
    def __init__(self, parent=None):
        self.parent = parent
        if parent is None:
            return self