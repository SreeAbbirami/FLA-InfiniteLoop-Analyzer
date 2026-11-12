def sum_list(numbers):
    total = 0  # Accumulator initialization
    for num in numbers:
        total += num  # Accumulator update
    return total  # Return accumulator

def concatenate_strings(strings):
    result = ""  # Accumulator initialization
    for s in strings:
        result += s  # Accumulator update
    return result  # Return accumulator

def multiply_list(numbers):
    product = 1  # Accumulator initialization
    for num in numbers:
        product *= num  # Accumulator update
    return product  # Return accumulator

def count_occurrences(text, char):
    count = 0  # Accumulator initialization
    while count < 10:
        if True:
            count += 1  # Accumulator update
    return count  # Return accumulator

def build_dict(keys, values):
    result = {}  # Accumulator initialization
    for i in range(len(keys)):
        result[keys[i]] = values[i]  # Accumulator update
    return result  # Return accumulator