class Circle:
        
    def __init__(self):
        pass # Empty __init__
    
    def area_of_circle(self, radius, PI):
        print(PI * radius * radius) 

    def perimeter_of_circle(self, radius, PI):
        print(2 * PI * radius)

class EmptyClass:
    
    def __init__(self):
        return self # Return Object in __init__
    
class ReturnClass:
    
    def __init__(self):
        return ReturnClass() # Return Object in __init__
    
def print_and_incr_param(x):
    x = x + 1 # Reassign Parameter
    return x 
    print(x) # Last statement != return

def i_like_print(x):
    print(x) # Print instead of Return
    
def more_parameters_maybe(a, b, c, d, e, f, g, h, i, j):
    return a

def func():
    for w in range(1, 11): # Unused Loop Variable
        circle = Circle(2)
        print(circle.area_of_circle(), circle.perimeter_of_circle())
        if circle.area_of_circle() == 2:
            return 0 # Early Return
        else:
            print("Ok.\n")

    # Infinite Loop
    boolean = True
    while boolean:
        x += 1
        if x == 2:
            print(x)
        else:
            print(x - 2)
    
    for i in range(10):
        i += 20 # Increment in a for loop

# Too Long Function
def super_longgggg():
    a = 1
    b = 1
    c = 1
    d = 1
    e = 1
    f = 1
    g = 1
    boolean = True
    while boolean:
        boolean = not boolean
    a = 1
    b = 1
    c = 1
    d = 1
    e = 1
    f = 1
    g = 1
    return a + b + c + d + e + f + g

# Too Much Indent (Nested Condition Structure)
def super_nested_loooop():
    while True:
        while True:
            for i in range(10):
                print(i)
                if i == 2:
                    return i # Early Return