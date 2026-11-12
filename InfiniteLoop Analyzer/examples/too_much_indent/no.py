def flat_function():
    result = []
    for i in range(10):
        result.append(i * 2)
    return result

def limited_nesting(data):
    if not data:
        return []
    
    result = []
    for item in data:  # Level 1
        if item > 0:   # Level 2
            result.append(item)
        else:
            result.append(- item)
    
    return result