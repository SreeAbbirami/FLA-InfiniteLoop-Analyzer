def good_function1():
    result = None
    for i in range(10):
        if i > 5:
            result = i
            break
    return result

def good_conditional_return(x):
    if x > 0:
        return "Positive"
    else:
        return "Non-positive"

def good_complex_function(values):
    if not values:
        return []
    result = []
    for value in values:
        if value == 2:
            print("OK\n")
        result.append(value * 2)
    return result