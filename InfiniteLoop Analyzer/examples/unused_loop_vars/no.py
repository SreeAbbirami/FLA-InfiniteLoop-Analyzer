def process_list(items):
    result = []
    for i in range(len(items)):
        result.append(items[i] * 2)
    return result

def process_dict(data):
    for key, value in data.items():
        print(f"Key: {key}, Value: {value}")

def multiple_vars():
    for i, j, k in [(1, 2, 3), (4, 5, 6)]:
        print(f"i: {i}, j: {j}, k: {k}")

def nested_loops():
    total = 0
    for i in range(5):
        for j in range(3):
            total += i * j
    return total

def last_function():
    for idx, _ in enumerate([(1, 2, 3), (4, 5, 6)]):
        # y and _ are unused
        print(f"Index {idx}, x: {x}")