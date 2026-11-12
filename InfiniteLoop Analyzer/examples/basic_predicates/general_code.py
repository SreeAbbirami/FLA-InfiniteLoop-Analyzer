# This file is used to test all the basic predicates

def my_function(a, b):
    x = a + b
    for i in range(10):
        x -= 1
    return 2 * x

class Animal:
    def __init__(self, name):
        self.name = name
    
    def is_tired(self):
        return True # Always Tired
    
if __name__ == '__main__':
    
    u = my_function(1, 3)
    boolean = True
    
    # Useless While Loop
    while boolean:
        boolean = not boolean