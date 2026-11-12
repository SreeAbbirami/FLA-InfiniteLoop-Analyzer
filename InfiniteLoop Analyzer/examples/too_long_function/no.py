def calculate_results(a, b, c, d, e, f, g, h, i, j):
    result1 = a + b
    result2 = c + d
    result3 = e + f
    result4 = g + h
    result5 = i + j

    return result1, result2, result3, result4, result5

def display_results(results):
    for result in results:
        print(result)

def short_function():
    values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    results = calculate_results(*values)

    display_results(results)






    print("Hello !\n")








    return sum(results)