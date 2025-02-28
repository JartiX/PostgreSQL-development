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

def call_interpolation_procedure(conn, input_temp, measurement_id):
    with conn.cursor() as cur:
        try:            
            cur.execute("CALL interpolate_temperature(%s, %s, %s)", (input_temp, measurement_id, None))
            
            result = cur.fetchone()[0]
            return result
        except Exception as e:
            print("Ошибка при вызове процедуры:", e)
            return None

def perform_calculation():
    conn = connect_db()
    if not conn:
        return

    measurement_id = 1
    temp = -14
    
    start_time = time.time()
    interpolated_values = call_interpolation_procedure(conn, temp, measurement_id)
    end_time = time.time()

    elapsed_time = end_time - start_time
    
    print(interpolated_values)
    print(f"Время расчета: {elapsed_time:.4f} секунд")
    conn.close()
    

if __name__ == "__main__":
    perform_calculation()