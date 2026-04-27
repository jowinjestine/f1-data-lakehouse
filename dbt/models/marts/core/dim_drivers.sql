with jolpica_drivers as (
    select * from {{ ref('stg_jolpica_drivers') }}
),

crosswalk as (
    select * from {{ ref('driver_crosswalk') }}
)

select
    coalesce(cw.normalized_id, jd.driver_id) as driver_key,
    jd.driver_id as jolpica_driver_id,
    jd.first_name,
    jd.last_name,
    jd.full_name,
    jd.date_of_birth,
    jd.nationality,
    coalesce(cw.abbreviation, jd.driver_code) as driver_code,
    jd.permanent_number
from jolpica_drivers jd
left join crosswalk cw
    on cw.source = 'jolpica'
    and cw.source_id = jd.driver_id
