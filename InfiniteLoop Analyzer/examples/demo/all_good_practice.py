class Circle:
        
    def __init__(self, radius):
        PI = 3.14
        self.radius = radius
    
    def area_of_circle(self):
        return self.PI * self.radius * self.radius

    def perimeter_of_circle(self):
        return 2 * self.PI * self.radius
    
def print_and_incr_param(x):
    print(x)
    return x + 1

if __name__ == '__main__':
    for i in range(1, 11):
        circle = Circle(i)
        print(circle.area_of_circle(), circle.perimeter_of_circle())