def good_loop1():
    for i in range(5):
        print(i)

def good_loop2():
    for idx in range(10):
        if idx % 2 == 0:
            continue
        print(idx)

def good_nested_loop():
    for i in range(3):
        for j in range(3):
            print(i, j)

def good_tuple_loop():
    for i, j in [(0, 1), (2, 3), (4, 5)]:
        print(i, j)

def good_loop_with_calculation():
    for i in range(5):
        value = i + 1
        print(value)