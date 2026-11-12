def deeply_nested_function():
    for i in range(10):  # Level 1
        if i > 5:        # Level 2
            for j in range(i):  # Level 3
                if j % 2 == 0:  # Level 4
                    print(j)

def another_nested_function(data):
    if data:  # Level 1
        for item in data:  # Level 2
            if item > 0:  # Level 3
                while item > 10:  # Level 4
                    item -= 1
                    print(item)

def nested_conditions(x, y):
    if x > 0:  # Level 1
        if y > 0:  # Level 2
            if x > y:  # Level 3
                return x
            else:  # Level 3
                if x == y:  # Level 4
                    return "Equal"
                else:
                    return y

def complex_nested_loops():
    for i in range(5):  # Level 1
        for j in range(5):  # Level 2
            for k in range(5):  # Level 3
                print(i, j, k)