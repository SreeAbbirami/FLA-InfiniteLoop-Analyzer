def process_list(items):
    result = []
    for i in range(len(items)):
        # i is never used in the loop body
        result.append(items[0] * 2)
    return result

def process_dict(data):
    for key, value in data.items():
        # key is never used 
        print(f"Value: {value}")

def multiple_vars():
    for i, j, k in [(1, 2, 3), (4, 5, 6)]:
        # j is unused
        if True:
            print(f"i: {i}, i + 1: {i + 1}")

def nested_loops():
    for i in range(5):
        for j in range(3):
            # j is unused
            print(f"i: {i}")