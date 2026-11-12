SUCCESS = 0

def calculate_sum(a, b):
    result = a + b
    return result  # Use of Return

def complex_function(data):
    try:
        x = 2
        if x > 0:
            return x  # Use of Return
        else:
            return "Negative"  # Use of Return
    except:
        x = 3
        if x > 0:
            return x  # Use of Return
        else:
            return "Negative"  # Use of Return
            
def process_data(data):
    if not data:
        return "No data provided"  # Use of Return
    else:
        total = sum(data)
        return total  # Use of Return
    
def process_data_try_except(data):
    try:
        x = 2
        return x # Use of Return
    except:
        x = 3
        return x # Use of Return
    
def main():
    sum_result = calculate_sum(5, 10)
    print("Sum:", sum_result)

    data_result = process_data([1, 2, 3, 4, 5])
    print("Data total:", data_result)

    double_sum = sum_result * 2
    print("Double sum:", double_sum)
    
    return SUCCESS # Use of Return

if __name__ == "__main__":
    main()