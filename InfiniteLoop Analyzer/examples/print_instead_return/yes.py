SUCCESS = 0

def calculate_sum(a, b):
    result = a + b
    print(result)  # Use of print() instead of Return

def process_data(data):
    if not data:
       return None
    else:
        total = sum(data)
    
    print(total)  # Use of print() instead of Return
    
def process_data_if_else(data):
    if not data:
       print("None") # Use of print() instead of Return
    else:
        total = sum(data)
        print(total) # Use of print() instead of Return
        
def process_data_try_except(data):
    try:
        x = 2
        print(x) # Use of print() instead of Return
    except:
        x = 3
        return 3 # Use of print() instead of Return

def complex_function(data):
    try:
        x = 2
        if x > 0:
            print(x)  # Use of print() instead of Return
        else:
            print("Negative")  # Use of print() instead of Return
    except:
        x = 3
        if x > 0:
            print(x)  # Use of print() instead of Return
        else:
            print("Negative")  # Use of print() instead of Return
            
def main():
    sum_result = calculate_sum(5, 10)
    print("Sum:", sum_result)

    data_result = process_data([1, 2, 3, 4, 5])
    print("Data total:", data_result)

    double_sum = sum_result * 2
    print("Double sum:", double_sum)
    
    print(SUCCESS) # Use of print() instead of Return

if __name__ == "__main__":
    main()