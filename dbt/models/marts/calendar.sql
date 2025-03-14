{%- set today_date = modules.datetime.date.today().strftime('%Y-%m-%d') -%}
{%- set ly_date = modules.datetime.date.today().replace(year=modules.datetime.date.today().year - 1).strftime('%Y-%m-%d') -%}
{%- set ply_date = modules.datetime.date.today().replace(year=modules.datetime.date.today().year - 2).strftime('%Y-%m-%d') -%}

with

source as (

    SELECT 
        calendar_id,
        calendar_year,
        calendar_quarter,
        calendar_month,
        calendar_week_of_year,
        calendar_day_of_year,
        gregorian_year,
        gregorian_period,
        gregorian_week,
        gregorian_day 
    FROM {{ source('urn:datacontract:project:jaffle-shop:dbt-seed:raw-model:calendar', 'raw_calendar') }}

),

slicers_year AS (

    SELECT DISTINCT 
        gregorian_year,
        'Current Year' AS gregorian_year_flag
    FROM source
    WHERE calendar_id = '{{ today_date }}'
    UNION
    SELECT DISTINCT
        gregorian_year,
        'Previous Year' AS gregorian_year_flag
    FROM source
    WHERE calendar_id = '{{ ly_date }}'
    UNION
    SELECT DISTINCT
        gregorian_year,
        '2 Years Ago' AS gregorian_year_flag
    FROM source
    WHERE calendar_id = '{{ ply_date }}'

),

slicers_period AS (

    SELECT DISTINCT 
        gregorian_year,
        gregorian_period,
        'Current Period' AS gregorian_period_flag
    FROM source
    WHERE calendar_id = '{{ today_date }}'
    UNION
    SELECT DISTINCT 
        CASE WHEN gregorian_period - 1 <= 0 THEN gregorian_year - 1 ELSE gregorian_year END AS gregorian_year,
        CASE WHEN gregorian_period - 1 <= 0 THEN 13 ELSE gregorian_period - 1 END AS gregorian_period,
        'Previous Period' AS gregorian_period_flag
    FROM source
    WHERE calendar_id = '{{ today_date }}'
    UNION
    SELECT DISTINCT 
        CASE WHEN gregorian_period - 2 <= 0 THEN gregorian_year - 1 ELSE gregorian_year END AS gregorian_year,
        CASE WHEN gregorian_period - 2 <= 0 THEN 13 - (2 - gregorian_period) ELSE gregorian_period - 2 END AS gregorian_period,
        '2 Periods Ago' AS gregorian_period_flag
    FROM source
    WHERE calendar_id = '{{ today_date }}'

),

slicers_year_progress AS (

    SELECT DISTINCT 
        gregorian_year,
        gregorian_period,
        'Year to Date' AS gregorian_year_progress_flag
    FROM source
    WHERE gregorian_year = ( SELECT MAX(gregorian_year) FROM slicers_year WHERE gregorian_year_flag = 'Current Year' ) AND
          gregorian_period <= ( SELECT MAX(gregorian_period) FROM slicers_period WHERE gregorian_period_flag = 'Current Period' )
    UNION
    SELECT DISTINCT 
        gregorian_year,
        gregorian_period,
        'Year to Go' AS gregorian_year_progress_flag
    FROM source
    WHERE gregorian_year = ( SELECT MAX(gregorian_year) FROM slicers_year WHERE gregorian_year_flag = 'Current Year' ) AND
          gregorian_period > ( SELECT MAX(gregorian_period) FROM slicers_period WHERE gregorian_period_flag = 'Current Period' )

),

slicers_period_progress AS (

    SELECT DISTINCT
        gregorian_year,
        gregorian_period,
        gregorian_week,
        gregorian_day,
        'Current Business Day' AS gregorian_period_progress_flag
    FROM source
    WHERE calendar_id = '{{ today_date }}'
    UNION
    SELECT DISTINCT
        gregorian_year,
        gregorian_period,
        gregorian_week,
        gregorian_day,
        'Period to Date' AS gregorian_period_progress_flag
    FROM source
    WHERE calendar_id < '{{ today_date }}' AND 
          gregorian_period = ( SELECT MAX(gregorian_period) FROM slicers_period WHERE gregorian_period_flag = 'Current Period' )
    UNION
    SELECT DISTINCT
        gregorian_year,
        gregorian_period,
        gregorian_week,
        gregorian_day,
        'Period to Go' AS gregorian_period_progress_flag
    FROM source
    WHERE calendar_id > '{{ today_date }}' AND 
          gregorian_period = ( SELECT MAX(gregorian_period) FROM slicers_period WHERE gregorian_period_flag = 'Current Period' )
          
)

SELECT 
    source.calendar_id,
    source.calendar_year,
    LEAST(source.calendar_quarter, 4) calendar_quarter,
    source.calendar_month,
    source.calendar_week_of_year,
    source.calendar_day_of_year,
    source.gregorian_year,
    LEAST(1+(source.gregorian_period div 4), 4) AS gregorian_quarter,
    source.gregorian_period,
    source.gregorian_week,
    source.gregorian_day,
    slicers_year.gregorian_year_flag,
    slicers_period.gregorian_period_flag,
    slicers_year_progress.gregorian_year_progress_flag,
    slicers_period_progress.gregorian_period_progress_flag
FROM source
LEFT JOIN slicers_year 
  ON slicers_year.gregorian_year = source.gregorian_year
LEFT JOIN slicers_period 
  ON slicers_period.gregorian_year = source.gregorian_year AND
     slicers_period.gregorian_period = source.gregorian_period
LEFT JOIN slicers_year_progress 
  ON slicers_year_progress.gregorian_year = source.gregorian_year AND
     slicers_year_progress.gregorian_period = source.gregorian_period
LEFT JOIN slicers_period_progress 
  ON slicers_period_progress.gregorian_year = source.gregorian_year AND
     slicers_period_progress.gregorian_period = source.gregorian_period AND
     slicers_period_progress.gregorian_week = source.gregorian_week AND
     slicers_period_progress.gregorian_day = source.gregorian_day;
