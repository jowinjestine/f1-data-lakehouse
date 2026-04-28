with jolpica_circuits as (
    select * from {{ ref('stg_jolpica_circuits') }}
),

crosswalk as (
    select * from {{ ref('circuit_crosswalk') }}
)

select
    coalesce(cw.normalized_id, jc.circuit_id) as circuit_key,
    jc.circuit_id as jolpica_circuit_id,
    coalesce(cw.normalized_name, jc.circuit_name) as circuit_name,
    jc.city,
    jc.country,
    jc.latitude,
    jc.longitude
from jolpica_circuits jc
left join crosswalk cw
    on cw.source = 'jolpica'
    and cw.source_id = jc.circuit_id
