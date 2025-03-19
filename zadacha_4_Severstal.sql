create table #temp_data( -- для создания временной таблицы к имени таблицы добавляется префикс # - это уже диалект T-SQL
    date_value date,
    count_value int
);

insert into #temp_data(date_value, count_value) values -- стандартный синтаксис sql для вставки данных
    ('2022-05-04', 5),
    ('2022-05-03', 2),
    ('2022-07-02', 6),
    ('2022-12-01', 3),
    ('2022-10-01', 1),
    ('2022-10-15', 1),
    ('2022-10-27', 7),
    ('2022-07-03', 2);

/*
Если есть сложная задача, то её лучше решать частями, поэтому использую CTE.
Общие табличные выражения можно представить как определения временных таблиц, существующих только для одного запроса. 
*/

/*
Табличное выражение "marked_data"

- Переменные:
  - date_value -- исходная дата из временной таблицы
  - count_value -- значение счетчика для каждой даты
  - formatted_date -- дата, отформатированная в виде 'dd.MM.yyyy' для удобства отображения
  - month_year -- месяц и год, отформатированные в виде 'MM.yyyy', используются для группировки
  - is_first_day -- флаг, указывающий, является ли дата первым числом месяца (1 - да, 0 - нет)
- Функции:
  - format() -- используется для форматирования даты в нужный вид.
  - case when ... then ... end -- используется для определения, является ли дата первым числом месяца.
- Логика:
  - Данные из временной таблицы разделяются на две категории: первые числа месяца и остальные даты.
*/

with marked_data as(
    select
        date_value,
        count_value,
        format(date_value, 'dd.MM.yyyy') as formatted_date,
        format(date_value, 'MM.yyyy') as month_year,
        case when day(date_value) = 1 then 1 else 0 end as is_first_day
    from #temp_data
),
/*
Табличное выражение "aggregated_data"

- Переменные:
	- month_year -- месяц и год, используются для группировки
	- total_count -- сумма значений счетчика для каждого месяца, исключая первые числа
- Логика:
  - Используется для вычисления общей суммы значений за месяц, исключая первые числа, чтобы потом можно было вычесть их из общей суммы
*/

aggregated_data as(
    select
        month_year,
        sum(count_value) as total_count
    from marked_data
    where is_first_day = 0 -- исключаем первые числа месяца
    group by month_year
),
/*
Табличное выражение "first_days"

- Переменные:
  - formatted_date -- отформатированная дата для первого числа месяца
  - count_value -- значение счетчика для первого числа месяца
- Логика:
  - Выбираются только те строки, где дата является первым числом месяца
*/

first_days as(
    select
        formatted_date as date,
        count_value as count,
        cast(substring(formatted_date, 7, 4) + substring(formatted_date, 4, 2) as int) as sort_key -- для сортировки
    from marked_data
    where is_first_day = 1 -- выбираем только первые числа месяца
),
/*
Табличное выражение "final_data"

- Переменные:
  - date -- месяц и год, отформатированные в виде 'MM.yyyy'
  - total_count -- общая сумма значений за месяц, исключая первые числа
- Логика:
  - Подготавливает данные для объединения с первыми числами месяца
*/

final_data as(
    select
        month_year as date,
        total_count as count,
        cast(substring(month_year, 4, 4) + substring(month_year, 1, 2) as int) as sort_key -- для сортировки
    from aggregated_data
)
-- объединяем результаты и сортируем
select
    date,
    count
from(
    select
        date,
        count,
        sort_key,
        1 as sort_order -- первые числа месяца идут первыми, как в примере выходных данных
    from first_days
    union all -- UNION ALL возвращает результирующий набор со всеми строками из двух входных наборов
    select
        date,
        count,
        sort_key,
        2 as sort_order -- месяцы идут вторыми
    from final_data
) as combined
order by sort_key, sort_order, date;

-- удаление временной таблицы, тк "Рекомендуется также удалить временные таблицы с помощью DROP TABLE, когда вы закончите работу с ними в коде."
drop table #temp_data;
