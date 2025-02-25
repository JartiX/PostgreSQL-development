import psycopg2
import time
import numpy as np


def connect_db():
    try:
        conn = psycopg2.connect(
            dbname="postgres", 
            user="admin", 
            password="123456", 
            host="localhost", 
            port="5432"
        )
        return conn
    except Exception as e:
        print("Ошибка подключения к базе данных:", e)
        return None

def get_temperature_data(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT temperature, correction FROM temperature_correction ORDER BY temperature ASC")
        temperature_data = cur.fetchall()
    return temperature_data

def calculate_interpolation(input_temp, temperature_data):
    temp_high = None
    temp_low = None
    delta_high = None
    delta_low = None
    
    for i in range(len(temperature_data) - 1):
        if temperature_data[i][0] <= input_temp <= temperature_data[i+1][0]:
            temp_low = np.float16(temperature_data[i][0])
            delta_low = np.float16(temperature_data[i][1])
            temp_high = np.float16(temperature_data[i+1][0])
            delta_high = np.float16(temperature_data[i+1][1])
            break
    
    if temp_low is None or temp_high is None:
        raise ValueError(f"Температура {input_temp} выходит за пределы таблицы")
    
    if temp_low == temp_high:
        delta = delta_low
    else:
        delta = delta_low + (input_temp - temp_low) * (delta_high - delta_low) / (temp_high - temp_low)

    return delta

def perform_calculation():
    conn = connect_db()
    if not conn:
        return

    start_time = time.time()

    results = []
    for temp in np.arange(0, 40.01, 0.01):
        temperature_data = get_temperature_data(conn)
        delta_t = calculate_interpolation(temp, temperature_data)
        results.append((temp, delta_t))

    end_time = time.time()

    elapsed_time = end_time - start_time
    print(f"Время расчета: {elapsed_time:.4f} секунд")
    conn.close()

if __name__ == "__main__":
    perform_calculation()