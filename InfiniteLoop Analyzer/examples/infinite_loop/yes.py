def function_bad_1():
    booleanValue = True
    otherBool = True
    i = 0
    j = 10
    while booleanValue:
        i += 1
        if j == i:
            booleanValue = otherBool # Bad because updated with another variable with the same value than itself.
    
    return booleanValue

def function_bad_2():
    i = 0
    j = 10
    while j == 10:
        i += 1
        if j == i:
            j = j # j updated to itself, so not OK


def function_bad_3():
    x = 2
    y = 0
    while x == 2:
        y -= 1 # Not Okay, because x is never updated (and the init cond is True)
    return x

while True: # True, so infinite loop
    i += 1