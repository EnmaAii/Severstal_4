create table #temp_data( -- ��� �������� ��������� ������� � ����� ������� ����������� ������� # - ��� ��� ������� T-SQL
    date_value date,
    count_value int
);

insert into #temp_data(date_value, count_value) values -- ����������� ��������� sql ��� ������� ������
    ('2022-05-04', 5),
    ('2022-05-03', 2),
    ('2022-07-02', 6),
    ('2022-12-01', 3),
    ('2022-10-01', 1),
    ('2022-10-15', 1),
    ('2022-10-27', 7),
    ('2022-07-03', 2);

/*
���� ���� ������� ������, �� � ����� ������ �������, ������� ��������� CTE.
����� ��������� ��������� ����� ����������� ��� ����������� ��������� ������, ������������ ������ ��� ������ �������. 
*/

/*
��������� ��������� "marked_data"

- ����������:
  - date_value -- �������� ���� �� ��������� �������
  - count_value -- �������� �������� ��� ������ ����
  - formatted_date -- ����, ����������������� � ���� 'dd.MM.yyyy' ��� �������� �����������
  - month_year -- ����� � ���, ����������������� � ���� 'MM.yyyy', ������������ ��� �����������
  - is_first_day -- ����, �����������, �������� �� ���� ������ ������ ������ (1 - ��, 0 - ���)
- �������:
  - format() -- ������������ ��� �������������� ���� � ������ ���.
  - case when ... then ... end -- ������������ ��� �����������, �������� �� ���� ������ ������ ������.
- ������:
  - ������ �� ��������� ������� ����������� �� ��� ���������: ������ ����� ������ � ��������� ����.
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
��������� ��������� "aggregated_data"

- ����������:
	- month_year -- ����� � ���, ������������ ��� �����������
	- total_count -- ����� �������� �������� ��� ������� ������, �������� ������ �����
- ������:
  - ������������ ��� ���������� ����� ����� �������� �� �����, �������� ������ �����, ����� ����� ����� ���� ������� �� �� ����� �����
*/

aggregated_data as(
    select
        month_year,
        sum(count_value) as total_count
    from marked_data
    where is_first_day = 0 -- ��������� ������ ����� ������
    group by month_year
),
/*
��������� ��������� "first_days"

- ����������:
  - formatted_date -- ����������������� ���� ��� ������� ����� ������
  - count_value -- �������� �������� ��� ������� ����� ������
- ������:
  - ���������� ������ �� ������, ��� ���� �������� ������ ������ ������
*/

first_days as(
    select
        formatted_date as date,
        count_value as count,
        cast(substring(formatted_date, 7, 4) + substring(formatted_date, 4, 2) as int) as sort_key -- ��� ����������
    from marked_data
    where is_first_day = 1 -- �������� ������ ������ ����� ������
),
/*
��������� ��������� "final_data"

- ����������:
  - date -- ����� � ���, ����������������� � ���� 'MM.yyyy'
  - total_count -- ����� ����� �������� �� �����, �������� ������ �����
- ������:
  - �������������� ������ ��� ����������� � ������� ������� ������
*/

final_data as(
    select
        month_year as date,
        total_count as count,
        cast(substring(month_year, 4, 4) + substring(month_year, 1, 2) as int) as sort_key -- ��� ����������
    from aggregated_data
)
-- ���������� ���������� � ���������
select
    date,
    count
from(
    select
        date,
        count,
        sort_key,
        1 as sort_order -- ������ ����� ������ ���� �������, ��� � ������� �������� ������
    from first_days
    union all -- UNION ALL ���������� �������������� ����� �� ����� �������� �� ���� ������� �������
    select
        date,
        count,
        sort_key,
        2 as sort_order -- ������ ���� �������
    from final_data
) as combined
order by sort_key, sort_order, date;

-- �������� ��������� �������, �� "������������� ����� ������� ��������� ������� � ������� DROP TABLE, ����� �� ��������� ������ � ���� � ����."
drop table #temp_data;
