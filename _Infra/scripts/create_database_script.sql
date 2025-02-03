-- measurement batch table
CREATE TABLE IF NOT EXISTS public.measurement_batch
(
    id integer NOT NULL,
    start_period timestamp without time zone DEFAULT now(),
    position_x numeric(8,2),
    position_y numeric(8,2),
    user_id integer NOT NULL,
    CONSTRAINT measurement_batch_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.measurement_batch
    OWNER to admin;

-- measurement parameters table
CREATE TABLE IF NOT EXISTS public.measurement_params
(
    id integer NOT NULL,
    measurement_type_id integer NOT NULL,
    measurement_batch_id integer NOT NULL,
    height numeric(8,2) DEFAULT 100,
    temperature numeric(8,2) DEFAULT 15,
    pressure numeric(8,2) DEFAULT 750,
    wind_speed numeric(8,2) DEFAULT 0,
    wind_direction numeric(8,2) DEFAULT 0,
    bullet_speed numeric(8,2),
    CONSTRAINT measurement_params_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.measurement_params
    OWNER to admin;

-- measurement types table
CREATE TABLE IF NOT EXISTS public.measurement_types
(
    id integer NOT NULL,
    name character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT measurement_types_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.measurement_types
    OWNER to admin;

-- ranks table
CREATE TABLE IF NOT EXISTS public.ranks
(
    id integer NOT NULL,
    rank_title character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT ranks_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.ranks
    OWNER to admin;

-- users table
CREATE TABLE IF NOT EXISTS public.users
(
    id integer NOT NULL,
    username character varying(100) COLLATE pg_catalog."default",
    rank_id integer NOT NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.users
    OWNER to admin;

-- sequence for users id
CREATE SEQUENCE IF NOT EXISTS public.users_sequence
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public.users_sequence
    OWNED BY public.users.id;

ALTER SEQUENCE public.users_sequence
    OWNER TO admin;

-- sequence for ranks id
CREATE SEQUENCE IF NOT EXISTS public.ranks_sequence
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public.ranks_sequence
    OWNED BY public.ranks.id;

ALTER SEQUENCE public.ranks_sequence
    OWNER TO admin;

-- sequence for measurement parameters id
CREATE SEQUENCE IF NOT EXISTS public.measurement_params_sequence
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public.measurement_params_sequence
    OWNED BY public.measurement_params.id;

ALTER SEQUENCE public.measurement_params_sequence
    OWNER TO admin;

-- sequence for measurement batch id
CREATE SEQUENCE IF NOT EXISTS public.measurement_batch_sequence
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE public.measurement_batch_sequence
    OWNED BY public.measurement_batch.id;

ALTER SEQUENCE public.measurement_batch_sequence
    OWNER TO admin;

-- using increment for id fields
alter table public.measurement_batch alter column
id set default nextval('public.measurement_batch_sequence');

alter table public.measurement_params alter column
id set default nextval('public.measurement_params_sequence');

alter table public.users alter column
id set default nextval('public.users_sequence');

alter table public.ranks alter column
id set default nextval('public.ranks_sequence');

-- fill with rows
insert into public.ranks (rank_title)
values
    ('Рядовой'),
    ('Ефрейтор'),
    ('Младший сержант'),
    ('Сержант'),
    ('Старший сержант'),
    ('Старшина'),
    ('Прапорщик'),
    ('Старший прапорщик'),
    ('Младший лейтенант'),
    ('Лейтенант'),
    ('Старший лейтенант'),
    ('Капитан'),
    ('Майор'),
    ('Подполковник'),
    ('Полковник'),
    ('Генерал-майор'),
    ('Генерал-лейтенант'),
    ('Генерал-полковник'),
    ('Генерал армии'),
    ('Маршал Российской Федерации'),
    ('Матрос'),
    ('Старший матрос'),
    ('Старшина 2 статьи'),
    ('Старшина 1 статьи'),
    ('Главный старшина'),
    ('Главный корабельный старшина'),
    ('Мичман'),
    ('Старший мичман'),
    ('Капитан-лейтенант'),
    ('Капитан 3 ранга'),
    ('Капитан 2 ранга'),
    ('Капитан 1 ранга'),
    ('Контр-адмирал'),
    ('Вице-адмирал'),
    ('Адмирал'),
    ('Адмирал флота');

insert into public.measurement_types (id, name)
values
	(1, 'ДМК'),
	(2, 'ВР');

insert into public.users (username, rank_id)
values
	('alena', 1),
	('nikita', 13);

insert into public.measurement_batch (start_period, user_id)
values
	('2025-01-31 11:24', 1),
	('2025-01-31 11:26', 2);

insert into public.measurement_params (measurement_type_id, measurement_batch_id, height, temperature, pressure, wind_speed, wind_direction, bullet_speed)
values
	(2, 1, 100, 14, 720, 14, 25, 10),
	(1, 2, 100, 14, 720, 14, 25, 10);

-- select * from public.users;
-- select * from public.ranks;
-- select * from public.measurement_batch;
-- select * from public.measurement_types;
-- select * from public.measurement_params;
