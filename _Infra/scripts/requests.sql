-- Изменение записи в таблице
update public.employees set military_rank_id=2 where id=3;

-- Получить список всех изменений для пользователя у которого ФИО "Воловиков Александр Сергеевич"
select * from public.measurement_input_params 
where id =
	(
		select measurement_input_param_id from public.measurement_batches
		where employee_id = 
			(
				select id from public.employees
				where
					name = 'Воловиков Александр Сергеевич'
			)
	)
-- Второй способ
select * from public.measurement_input_params as t1
left join public.measurement_batches as t2
on t2.measurement_input_param_id=t1.id
left join public.employees as t3
on t3.id = t2.employee_id
where t3.name = 'Воловиков Александр Сергеевич'


-- Получить пользователей которые делали измерения на высоте 300 метров
select * from public.employees
where id =
	(
	select employee_id from public.measurement_batches
	where measurement_input_param_id =
		(
		select id from public.measurement_input_params
		where height = 300
		)
	)
-- Второй способ
select * from public.employees as t1
left join measurement_batches as t2
on t2.employee_id = t1.id
inner join measurement_input_params as t3
on t2.measurement_input_param_id = t3.id
where
	t3.height = 300


-- Сортировка (Первый с конца по айди)
select * from public.measurement_types order by id desc
limit 1;


-- Написать запрос, который получается значения delta_t и temperature рядом с заданной температурой 22 (для последующей интерполяции)
SELECT * FROM 
(
    SELECT delta_t, temperature FROM temperature_correction
    WHERE temperature > 22
    ORDER BY id
    LIMIT 1
)
LEFT JOIN (
    SELECT delta_t, temperature FROM temperature_correction
    WHERE temperature < 22
    ORDER BY id DESC
    LIMIT 1
)
ON true;