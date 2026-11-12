def function1():
    booleanValue = True
    i = 0
    j = 10
    while booleanValue:
        i += 1
        if j == i:
            booleanValue = not booleanValue # booleanValue updated, so OK
    
    return booleanValue

def function2():
    booleanValue = True
    i = 0
    j = 10
    while j == 10:
        i += 1
        if j == i:
            j = j + 1 # j updated to another value, so OK (even if the cond stay True !)
    
    return booleanValue

def function3():
    while False: # Always not infinite loop
        i += 1
    return True


x = 2
while x == 2:
    x = 1 # Updated, so OK