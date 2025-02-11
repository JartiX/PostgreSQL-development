DO $$
DECLARE
    input_temp numeric(8,2) := 7.5;
    temp_interpolation interpolation;
    delta numeric(8,2);

BEGIN
    -- Находим ближайшие точки для интерполяции
    SELECT 
        t1.delta_t, t1.temperature,
        t2.delta_t, t2.temperature
    INTO 
        temp_interpolation.delta_high, temp_interpolation.temp_high,
        temp_interpolation.delta_low, temp_interpolation.temp_low
    FROM
    (
        SELECT delta_t, temperature FROM temperature_correction
        WHERE temperature >= input_temp
        ORDER BY id
        LIMIT 1
    ) AS t1
    LEFT JOIN 
    (
        SELECT delta_t, temperature FROM temperature_correction
        WHERE temperature <= input_temp
        ORDER BY id DESC
        LIMIT 1
    ) AS t2
    ON true;

    IF temp_interpolation.temp_low IS NULL OR temp_interpolation.temp_high IS NULL THEN
        RAISE EXCEPTION 'Температура % выходит за пределы таблицы', input_temp;
    END IF;

    -- Вычисляем поправку с помощью линейной интерполяции
    IF temp_interpolation.temp_low = temp_interpolation.temp_high THEN
        delta := temp_interpolation.delta_low;
    ELSE
        delta := temp_interpolation.delta_low + 
                (input_temp - temp_interpolation.temp_low) * 
                (temp_interpolation.delta_high - temp_interpolation.delta_low) / 
                (temp_interpolation.temp_high - temp_interpolation.temp_low);
    END IF;

    RAISE NOTICE 'Поправка для температуры %: %', input_temp, delta;

END $$;