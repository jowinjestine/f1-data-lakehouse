with jolpica_constructors as (
    select * from {{ ref('stg_jolpica_constructors') }}
),

crosswalk as (
    select * from {{ ref('constructor_crosswalk') }}
)

select
    coalesce(cw.normalized_id, jc.constructor_id) as constructor_key,
    jc.constructor_id as jolpica_constructor_id,
    coalesce(cw.normalized_name, jc.constructor_name) as constructor_name,
    jc.nationality
from jolpica_constructors jc
left join crosswalk cw
    on cw.source = 'jolpica'
    and cw.source_id = jc.constructor_id
