def bad_loop1():
    for i in range(5):
        print(i)
        i += 1  # Incrementing loop variable

def bad_nested_loop():
    for i in range(3):
        for j in range(3):
            j += 1  # Incrementing nested loop variable
            print(i, j)
        
def bad_tuple_loop():
    for i, j in [(0, 1), (2, 3), (4, 5)]:
        i += 1  # Incrementing first element of tuple
        print(i, j)

def bad_loop_complex():
    for i in range(5):
        if i == 2:
            i += 2  # Skipping values by incrementing
        print(i)

def bad_loop2():
    for idx in range(10):
        if idx % 2 == 0:
            idx += 1  # Conditional increment of loop variable
        print(idx)