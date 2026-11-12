def process_list(numbers):
    # Using built-in sum instead of accumulator
    return sum(numbers)

def concatenate_strings(strings):
    # Using join instead of accumulator
    return "".join(strings)

def multiply_values(a, b):
    return a * b

def map_values(items):
    # Using list comprehension instead of accumulator
    return [item * 2 for item in items]

def create_dict(keys, values):
    # Using dict comprehension instead of accumulator
    return {k: v for k, v in zip(keys, values)}

def process_data(data):
    if not data:
        return None
    first_item = data[0]
    if first_item > 10:
        return "Large"
    else:
        return "Small"
    
def almost_accumulator():
    x = 0
    for i in range(10):
        x += i
    print(x)
    return 0