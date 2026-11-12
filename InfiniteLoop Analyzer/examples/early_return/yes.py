def bad_function1():
    for i in range(10):
        return i  # Early return in for loop
    print("This will never be reached")

def bad_function2(numbers):
    for num in numbers:
        if num > 5:
            return num # Early return in for loop
    print("No number greater than 5")
    return None

def bad_nested_function():
    for i in range(5):
        for j in range(5):
            return i * j  # Conditional early return in nested loop
        print("This won't execute")
    return 0

def bad_while_function():
    i = 0
    while i < 10:
        return i  # Early return in while loop
        i += 1
    print("Never reached")

def bad_complex_loop():
    values = []
    for i in range(10):
        if i % 2 == 0:
            return i  # Conditional early return
        values.append(i)
    return values