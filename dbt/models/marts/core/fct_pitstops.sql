select
    pitstop_id,
    year,
    round_number,
    driver_id,
    stop_number,
    lap,
    duration_string,
    'jolpica' as data_source
from {{ ref('stg_jolpica_pitstops') }}
