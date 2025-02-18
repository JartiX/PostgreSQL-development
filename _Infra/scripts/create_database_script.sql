DO $$
BEGIN
RAISE NOTICE 'Запускаем создание новой структуры базы данных'; 

BEGIN
	-- Связи
	alter table if exists public.measurement_input_params
	drop constraint if exists measurement_type_id_constraint;

	alter table if exists public.employees
	drop constraint if exists military_rank_id_constraint;

	alter table if exists public.measurement_batches
	drop constraint if exists measurement_input_param_id_constraint;

	alter table if exists public.measurement_batches
	drop constraint if exists employee_id_constraint;

	-- Таблицы
	drop table if exists public.measurement_input_params;
	drop table if exists public.measurement_batches;
	drop table if exists public.employees;
	drop table if exists public.measurement_types;
	drop table if exists public.military_ranks;
	drop table if exists public.temperature_correction;
	drop table if exists public.constant_table;
	drop table if exists public.meteo_average;

	-- Нумераторы
	drop sequence if exists public.measurement_input_params_seq;
	drop sequence if exists public.measurement_batches_seq;
	drop sequence if exists public.employees_seq;
	drop sequence if exists public.military_ranks_seq;
	drop sequence if exists public.measurement_types_seq;

	-- Типы
	drop type if exists interpolation_type cascade;
	drop type if exists measurement_input_params_type cascade;
	drop type if exists meteo_average_type cascade;

	-- Функции
	DROP FUNCTION IF EXISTS "CalculateInterpolation";
	DROP FUNCTION IF EXISTS "fnHeaderGetPressure";
	DROP FUNCTION IF EXISTS "validateMeasurementParams";
	DROP FUNCTION IF EXISTS "getFormattedDate";
	DROP FUNCTION IF EXISTS "formatHeight";
	DROP FUNCTION IF EXISTS "CalculateMeteoAverage";
END;
raise notice 'Удаление старых данных выполнено успешно';

-- Добавление структур данных
BEGIN
	-- Справочник должностей
	CREATE TABLE military_ranks
	(
		id integer primary KEY NOT NULL,
		description character varying(255)
	);

	INSERT INTO military_ranks(id, description)
	VALUES
		(1, 'Рядовой'),
		(2, 'Лейтенант');
	CREATE SEQUENCE military_ranks_seq START 3;

	ALTER TABLE military_ranks
		ALTER COLUMN id
		SET DEFAULT nextval('public.military_ranks_seq');
END;

BEGIN
	-- Пользователя
	CREATE TABLE employees
	(
		id integer primary KEY NOT NULL,
		name text,
		birthday timestamp ,
		military_rank_id integer
	);

	INSERT INTO employees(id, name, birthday,military_rank_id )  
	VALUES
		(1, 'Воловиков Александр Сергеевич','1978-06-24', 2),
		(2, 'Олег Михайлович Залыгин', '1990-10-12', '1');

	CREATE SEQUENCE employees_seq START 2;

	ALTER TABLE employees
		ALTER COLUMN id
		SET DEFAULT nextval('public.employees_seq');


END;

BEGIN
	-- Устройства для измерения
	CREATE TABLE measurement_types
	(
	id integer primary KEY NOT NULL,
	short_name  character varying(50),
	description text 
	);

	INSERT INTO measurement_types(id, short_name, description)
	VALUES
		(1, 'ДМК', 'Десантный метео комплекс'),
		(2,'ВР','Ветровое ружье');

	CREATE SEQUENCE measurement_types_seq START 3;

	ALTER TABLE measurement_types
		ALTER COLUMN id
		SET DEFAULT nextval('public.measurement_types_seq');
END;

BEGIN
	-- Таблица с параметрами
	CREATE TABLE measurement_input_params
	(
		id integer primary KEY NOT NULL,
		measurement_type_id integer NOT NULL,
		height numeric(8,2) DEFAULT 0,
		temperature numeric(8,2) DEFAULT 0,
		pressure numeric(8,2) DEFAULT 0,
		wind_direction numeric(8,2) DEFAULT 0,
		wind_speed numeric(8,2) DEFAULT 0
	);

	INSERT INTO measurement_input_params(id, measurement_type_id, height, temperature, pressure, wind_direction,wind_speed )
	VALUES
		(1, 1, 100,12,34,0.2,45);

	CREATE SEQUENCE measurement_input_params_seq START 2;

	ALTER TABLE measurement_input_params
		ALTER COLUMN id
		SET DEFAULT nextval('public.measurement_input_params_seq');

END;

BEGIN
	-- Таблица с историей
	CREATE TABLE measurement_batches
	(
		id integer primary KEY NOT NULL,
		employee_id integer NOT NULL,
		measurement_input_param_id integer NOT NULL,
		started timestamp DEFAULT now()
	);


	INSERT INTO measurement_batches(id, employee_id, measurement_input_param_id)
	VALUES
		(1, 1, 1);

	CREATE SEQUENCE measurement_batches_seq START 2;

	ALTER TABLE measurement_batches
		ALTER COLUMN id
		SET DEFAULT nextval('public.measurement_batches_seq');


END;

BEGIN
	-- Столбец с датой в measurement_types
	ALTER TABLE public.measurement_types
	ADD COLUMN started timestamp DEFAULT now();
END;

BEGIN
	create table meteo_average
	(
		date text,
		height text,
		temperature_pressure_deviation text
	);
END;

raise notice 'Создание общих справочников и наполнение выполнено успешно'; 

-- Подготовка рассчетных структур
BEGIN
	-- Таблица корректировки температуры
	CREATE TABLE temperature_correction
	(
		temperature numeric(8,2) PRIMARY KEY,
		delta_t numeric(8,2)
	);

	INSERT INTO public.temperature_correction(temperature, delta_t)
	VALUES
		(0, 0.5),
		(5, 0.5),
		(10, 1),
		(15, 1),
		(20, 1.5),
		(25, 2),
		(30, 3.5),
		(40, 4.5);
	
	-- Таблица для хранения констант
	create table constant_table (
		name character varying(255) primary key,
		value text
	);

	insert into public.constant_table(name, value)
	values
		('ground_pressure', '750.00'),
		('ground_virtual_temperature', '15.90'),
		('temp_low', '-58'),
		('temp_high', '58'),
		('pressure_low', '500'),
		('pressure_high', '900'),
		('wind_direction_low', '0'),
		('wind_direction_high', '59'),
		('wind_speed_low', '0'),
		('wind_speed_high', '15'),
		('bullets_drift_low', '0'),
		('bullets_drift_high', '150');

	-- Тип данных для хранения точек интерполяции
	CREATE TYPE interpolation_type AS (
		temp_low float,
		delta_low float,
		temp_high float,
		delta_high float
	);

	CREATE TYPE measurement_input_params_type AS (
		measurement_type_id integer,
		height numeric(8,2),
		temperature numeric(8,2),
		pressure numeric(8,2),
		wind_direction numeric(8,2),
		wind_speed numeric(8,2)
	);

	CREATE TYPE meteo_average_type AS (
		time text,
		pressure_temp text,
		height text
	);
END;

raise notice 'Расчетные структуры сформированы';

-- Создание связей
begin
	ALTER TABLE public.measurement_batches
		ADD CONSTRAINT employee_id_constraint
		FOREIGN KEY (employee_id)
		REFERENCES public.employees(id);

	ALTER TABLE public.measurement_batches
		ADD CONSTRAINT measurement_input_param_id_constraint
		FOREIGN KEY (measurement_input_param_id)
		REFERENCES public.measurement_input_params(id);
	
	ALTER TABLE public.measurement_input_params
		ADD CONSTRAINT measurement_type_id_constraint
		FOREIGN KEY (measurement_type_id)
		REFERENCES public.measurement_types(id);
	
	ALTER TABLE public.employees
		ADD CONSTRAINT military_rank_id_constraint
		FOREIGN KEY (military_rank_id)
		REFERENCES public.military_ranks(id);
end;
raise notice 'Связи сформированы';

-- Создание функций
begin
-- Функция для рассчета интерполяции температур
CREATE FUNCTION "CalculateInterpolation"(
    input_temp numeric(8,2)
)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    temp_interpolation interpolation_type;
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
        ORDER BY temperature
        LIMIT 1
    ) AS t1
    LEFT JOIN 
    (
        SELECT delta_t, temperature FROM temperature_correction
        WHERE temperature <= input_temp
        ORDER BY temperature DESC
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

    RETURN delta;

END;
$BODY$;
end;

-- Функция для возврата форматированной даты "ДДЧЧМ"
begin
CREATE FUNCTION "getFormattedDate"() 
	RETURNS TEXT 
	LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    current_time TIMESTAMP := NOW();
    formatted_date TEXT;
BEGIN
    formatted_date := TO_CHAR(current_time, 'DDHHMI');
    
    RETURN formatted_date;
END;
$BODY$;
end;

-- Функция для рассчета давления и интерполированной температуры в формате "БББТТ"
begin
CREATE FUNCTION "fnHeaderGetPressure"(
    pressure numeric,
	temperature numeric
)
    RETURNS text
    LANGUAGE 'plpgsql'
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE 
    var_pressure_constant numeric;
	var_temperature_constant numeric;
    var_diff integer;
    var_result text;
	interpolated_temperature numeric;
BEGIN
    SELECT value::numeric INTO var_pressure_constant 
    FROM constant_table
    WHERE name = 'ground_pressure';
    SELECT value::numeric INTO var_temperature_constant 
    FROM constant_table
    WHERE name = 'ground_virtual_temperature';

    var_diff := pressure - var_pressure_constant;

    var_result := lpad(abs(var_diff)::text, 3, '0');

    IF var_diff < 0 THEN
        var_result := '5' || var_result;
    ELSE
        var_result := '0' || var_result;
    END IF;
	interpolated_temperature := "CalculateInterpolation"(temperature) + temperature;
	var_result := var_result || lpad(replace(round(interpolated_temperature-var_temperature_constant)::text, '-', '5'), 2, '0');

    RETURN var_result;
END;
$BODY$;
end;

begin 
CREATE FUNCTION "CalculateMeteoAverage"(
	p_temperature numeric,
	p_pressure numeric,
	height numeric
)
	RETURNS meteo_average_type
	LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
	height_formatted text;
	pressure_temp_formatted text;
	time_formatted text;
	meteo_type meteo_average_type;
BEGIN
	select "formatHeight"(height=>height) into height_formatted;
	select "fnHeaderGetPressure"(pressure=>p_pressure, temperature=>p_temperature) into pressure_temp_formatted;
	select "getFormattedDate"() into time_formatted;
	meteo_type.pressure_temp = pressure_temp_formatted;
	meteo_type.time = time_formatted;
	meteo_type.height = height_formatted;

	RETURN meteo_type;
END;
$BODY$;
end;

begin
CREATE FUNCTION "formatHeight"(height NUMERIC) 
	RETURNS TEXT
	LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    formatted_height TEXT;
BEGIN
    formatted_height := LPAD(FLOOR(height)::TEXT, 4, '0');
    
    RETURN formatted_height;
END;
$BODY$;
end;

begin
-- Создаем функцию, которая принимает входные параметры и возвращает пользовательский тип данных
CREATE FUNCTION "validateMeasurementParams"(
    p_measurement_type_id integer,
    p_height numeric(8,2),
    p_temperature numeric(8,2),
    p_pressure numeric(8,2),
    p_wind_direction numeric(8,2),
    p_wind_speed numeric(8,2)
) 
	RETURNS measurement_input_params_type
	LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_result measurement_input_params_type;
    v_temp_low numeric;
    v_temp_high numeric;
    v_pressure_low numeric;
    v_pressure_high numeric;
    v_wind_direction_low numeric;
    v_wind_direction_high numeric;
    v_wind_speed_low numeric;
    v_wind_speed_high numeric;
BEGIN
    -- Проверка на соответствие типу данных
    IF pg_typeof(p_measurement_type_id) <> 'integer'::regtype THEN
        RAISE EXCEPTION 'p_measurement_type_id должен быть числовым';
    END IF;
    IF pg_typeof(p_height) <> 'numeric'::regtype THEN
        RAISE EXCEPTION 'p_height должен быть числовым';
    END IF;

    IF pg_typeof(p_temperature) <> 'numeric'::regtype THEN
        RAISE EXCEPTION 'p_temperature должен быть числовым';
    END IF;

    IF pg_typeof(p_pressure) <> 'numeric'::regtype THEN
        RAISE EXCEPTION 'p_pressure должен быть числовым';
    END IF;

    IF pg_typeof(p_wind_direction) <> 'numeric'::regtype THEN
        RAISE EXCEPTION 'p_wind_direction должен быть числовым';
    END IF;

    IF pg_typeof(p_wind_speed) <> 'numeric'::regtype THEN
        RAISE EXCEPTION 'p_wind_speed должен быть числовым';
    END IF;

    -- Получаем граничные значения из таблицы constant_table
    SELECT 
        value::numeric INTO v_temp_low
    FROM constant_table
    WHERE name = 'temp_low';

    SELECT 
        value::numeric INTO v_temp_high
    FROM constant_table
    WHERE name = 'temp_high';

    SELECT 
        value::numeric INTO v_pressure_low
    FROM constant_table
    WHERE name = 'pressure_low';

    SELECT 
        value::numeric INTO v_pressure_high
    FROM constant_table
    WHERE name = 'pressure_high';

    SELECT 
        value::numeric INTO v_wind_direction_low
    FROM constant_table
    WHERE name = 'wind_direction_low';

    SELECT 
        value::numeric INTO v_wind_direction_high
    FROM constant_table
    WHERE name = 'wind_direction_high';

    SELECT 
        value::numeric INTO v_wind_speed_low
    FROM constant_table
    WHERE name = 'wind_speed_low';

    SELECT 
        value::numeric INTO v_wind_speed_high
    FROM constant_table
    WHERE name = 'wind_speed_high';

    IF p_measurement_type_id IS NULL OR p_measurement_type_id < 1 THEN
        RAISE EXCEPTION 'measurement_type_id должен быть позитивным целым';
    END IF;

    IF p_temperature IS NULL OR p_temperature < v_temp_low OR p_temperature > v_temp_high THEN
        RAISE EXCEPTION 'temperature должен быть в диапазоне (%, %)', v_temp_low, v_temp_high;
    END IF;

    IF p_pressure IS NULL OR p_pressure < v_pressure_low OR p_pressure > v_pressure_high THEN
        RAISE EXCEPTION 'pressure должен быть в диапазоне (%, %)', v_pressure_low, v_pressure_high;
    END IF;

    IF p_wind_direction IS NULL OR p_wind_direction < v_wind_direction_low OR p_wind_direction > v_wind_direction_high THEN
        RAISE EXCEPTION 'wind_direction должен быть в диапазоне (%, %)', v_wind_direction_low, v_wind_direction_high;
    END IF;

    IF p_wind_speed IS NULL OR p_wind_speed < v_wind_speed_low OR p_wind_speed > v_wind_speed_high THEN
        RAISE EXCEPTION 'wind_speed должен быть в диапазоне (%, %)', v_wind_speed_low, v_wind_speed_high;
    END IF;

    v_result.measurement_type_id := p_measurement_type_id;
    v_result.height := p_height;
    v_result.temperature := p_temperature;
    v_result.pressure := p_pressure;
    v_result.wind_direction := p_wind_direction;
    v_result.wind_speed := p_wind_speed;

    RETURN v_result;
END;
$BODY$;
end;

raise notice 'Структура сформирована успешно';

END $$;
