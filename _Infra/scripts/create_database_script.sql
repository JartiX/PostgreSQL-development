do $$

BEGIN
	-- Справочник должностей
	CREATE TABLE IF NOT EXISTS military_ranks
	(
		id integer primary KEY NOT NULL,
		description character varying(255)
	);

	INSERT INTO military_ranks(id, description)
	VALUES
		(1, 'Рядовой'),
		(2, 'Лейтенант')
	ON conflict (id) do nothing;

	CREATE SEQUENCE IF NOT EXISTS military_ranks_seq START 3;

	ALTER TABLE military_ranks
		ALTER COLUMN id
		SET DEFAULT nextval('public.military_ranks_seq');

	-- Пользователя
	CREATE TABLE IF NOT EXISTS employees
	(
		id integer primary KEY NOT NULL,
		name text,
		birthday timestamp ,
		military_rank_id integer
	);

	INSERT INTO employees(id, name, birthday,military_rank_id )  
	VALUES
		(1, 'Воловиков Александр Сергеевич','1978-06-24', 2),
		(2, 'Олег Михайлович Залыгин', '1990-10-12', '1')
	ON conflict (id) do nothing;

	CREATE SEQUENCE IF NOT EXISTS employees_seq START 2;

	ALTER TABLE employees
		ALTER COLUMN id
		SET DEFAULT nextval('public.employees_seq');

	ALTER TABLE public.employees
		DROP CONSTRAINT IF EXISTS military_rank_id_constraint,
		ADD CONSTRAINT military_rank_id_constraint
		FOREIGN KEY (military_rank_id)
		REFERENCES public.military_ranks(id);

	-- Устройства для измерения
	CREATE TABLE IF NOT EXISTS measurement_types
	(
	id integer primary KEY NOT NULL,
	short_name  character varying(50),
	description text 
	);

	INSERT INTO measurement_types(id, short_name, description)
	VALUES
		(1, 'ДМК', 'Десантный метео комплекс'),
		(2,'ВР','Ветровое ружье')
	ON conflict (id) do nothing;

	CREATE SEQUENCE IF NOT EXISTS measurement_types_seq START 3;

	ALTER TABLE measurement_types
		ALTER COLUMN id
		SET DEFAULT nextval('public.measurement_types_seq');

	-- Таблица с параметрами
	CREATE TABLE IF NOT EXISTS measurement_input_params
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
		(1, 1, 100,12,34,0.2,45)
	ON conflict (id) do nothing;

	CREATE SEQUENCE IF NOT EXISTS measurement_input_params_seq START 2;

	ALTER TABLE measurement_input_params
		ALTER COLUMN id
		SET DEFAULT nextval('public.measurement_input_params_seq');

	ALTER TABLE public.measurement_input_params
		DROP CONSTRAINT IF EXISTS measurement_type_id_constraint,
		ADD CONSTRAINT measurement_type_id_constraint
		FOREIGN KEY (measurement_type_id)
		REFERENCES public.measurement_types(id);

	-- Таблица с историей
	CREATE TABLE IF NOT EXISTS measurement_batches
	(
			id integer primary KEY NOT NULL,
			employee_id integer NOT NULL,
			measurement_input_param_id integer NOT NULL,
			started timestamp DEFAULT now()
	);


	INSERT INTO measurement_batches(id, employee_id, measurement_input_param_id)
	VALUES
		(1, 1, 1)
	ON conflict (id) do nothing;

	CREATE SEQUENCE IF NOT EXISTS measurement_batches_seq START 2;

	ALTER TABLE measurement_batches
		ALTER COLUMN id
		SET DEFAULT nextval('public.measurement_batches_seq');

	ALTER TABLE public.measurement_batches
		DROP CONSTRAINT IF EXISTS employee_id_constraint,
		ADD CONSTRAINT employee_id_constraint
		FOREIGN KEY (employee_id)
		REFERENCES public.employees(id);

	ALTER TABLE public.measurement_batches
		DROP CONSTRAINT IF EXISTS measurement_input_param_id_constraint,
		ADD CONSTRAINT measurement_input_param_id_constraint
		FOREIGN KEY (measurement_input_param_id)
		REFERENCES public.measurement_input_params(id);

	-- Столбец с датой в measurement_types
	ALTER TABLE public.measurement_types
	ADD COLUMN IF NOT EXISTS started timestamp DEFAULT now();

	-- Таблица корректировки температуры
	CREATE TABLE IF NOT EXISTS temperature_correction
	(
		id integer primary KEY NOT NULL,
		temperature numeric(8,2),
		delta_t numeric(8,2)
	);

	INSERT INTO public.temperature_correction(id, temperature, delta_t)
	VALUES
		(1, 0, 0),
		(2, 5, 0.5),
		(3, 10, 1),
		(4, 15, 1),
		(5, 20, 1.5),
		(6, 25, 2),
		(7, 30, 3.5),
		(8, 40, 4.5)
	ON conflict (id) do nothing;
		
	CREATE SEQUENCE IF NOT EXISTS temperature_correction_seq START 9;

	ALTER TABLE temperature_correction
		ALTER COLUMN id
		SET DEFAULT nextval('public.temperature_correction_seq');

	-- Тип данных для хранения точек интерполяции
	IF NOT EXISTS (
		SELECT 1
		FROM pg_type
		WHERE typname = 'interpolation'
	) THEN
		CREATE TYPE interpolation AS (
			temp_low float,
			delta_low float,
			temp_high float,
			delta_high float
		);
	END IF;

END $$;
