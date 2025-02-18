-- Очистка таблиц перед вставкой
TRUNCATE TABLE measurement_batches CASCADE;
TRUNCATE TABLE measurement_input_params CASCADE;
TRUNCATE TABLE employees CASCADE;

-- Добавляем тестовых сотрудников
INSERT INTO employees (id, name, birthday, military_rank_id) VALUES
    (1, 'Иван Петров', '1985-06-15', 1),
    (2, 'Александр Македонский', '1990-09-21', 2),
    (3, 'Мария Иванова', '1995-03-10', 1);

-- Генерация 100 измерений для каждого сотрудника
DO $$
DECLARE
    emp_id INTEGER;
    i INTEGER;
    v_measurement_id INTEGER;
    v_batch_id INTEGER;
    v_measurement_type_id INTEGER;
    v_height NUMERIC(8,2);
    v_temperature NUMERIC(8,2);
    v_pressure NUMERIC(8,2);
    v_wind_direction NUMERIC(8,2);
    v_wind_speed NUMERIC(8,2);
    
    checked_measurements measurement_input_params_type;
BEGIN
    FOR emp_id IN (SELECT id FROM employees) LOOP
        FOR i IN 1..100 LOOP
            -- Генерация случайных данных
            v_measurement_type_id := 1 + floor(random()::numeric * 2);
            v_height := round((50 + random() * 200)::numeric, 2);
            v_temperature := round((-30 + random() * 80)::numeric, 2);
            v_pressure := round((500 + random() * 400)::numeric, 2);
            v_wind_direction := round((random() * 58)::numeric, 2);
            v_wind_speed := round((random() * 15)::numeric, 2);

            checked_measurements := "validateMeasurementParams"(v_measurement_type_id, v_height, v_temperature, v_pressure, v_wind_direction, v_wind_speed);

            INSERT INTO measurement_input_params (
                measurement_type_id, height, temperature, pressure, wind_direction, wind_speed
            ) VALUES (
                checked_measurements.measurement_type_id, checked_measurements.height, checked_measurements.temperature, checked_measurements.pressure, checked_measurements.wind_direction, checked_measurements.wind_speed
            ) RETURNING id INTO v_measurement_id;

            INSERT INTO measurement_batches (employee_id, measurement_input_param_id, started)
            VALUES (emp_id, v_measurement_id, now()) RETURNING id INTO v_batch_id;
        END LOOP;
    END LOOP;
END $$;
