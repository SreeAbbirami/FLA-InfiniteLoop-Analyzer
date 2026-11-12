def bad_function1(x, y):
    x = 10  # Reassigning parameter x
    return x + y

def bad_function2(values):
    values = []  # Reassigning parameter values
    for i in range(10):
        values.append(i)
    return values

def bad_function3(a, b, c):
    result = a + b
    c = result  # Reassigning parameter c
    return c

def bad_function4(data, factor):
    for i in range(len(data)):
        data[i] *= factor
    factor = 1  # Reassigning parameter factor
    return data

def bad_function5(x, y):
    x += 1  # Augmented assignment to parameter x
    y = 3   # Reassigning parameter y
    return x - y