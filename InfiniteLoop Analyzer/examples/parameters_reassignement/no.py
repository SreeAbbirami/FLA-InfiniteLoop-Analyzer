def good_function1(x, y):
    result = x + 10  # Using parameter without reassignment
    return result + y

def good_function2(values):
    new_values = []  # Creating new list instead of reassigning
    for i in range(10):
        new_values.append(i)
    return new_values

def good_function3(a, b, c):
    result = a + b + c
    return result

def good_function4(data, factor):
    result = []
    for item in data:
        result.append(item * factor)
    return result

def good_function5(x):
    result = x + 1  # Not reassigning the parameter
    return result