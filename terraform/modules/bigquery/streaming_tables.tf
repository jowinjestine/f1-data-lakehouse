# ── f1_streaming dataset and native tables for OpenF1 data ────────────────────
#
# 16 tables: 14 timing collections + sessions + meetings.
# High-volume tables are partitioned by DATE(date) and clustered on
# session_key + driver_number. Low-volume tables use ingestion-time
# partitioning or none.

resource "google_bigquery_dataset" "streaming" {
  dataset_id  = "f1_streaming"
  project     = var.project_id
  location    = var.location
  description = "OpenF1 live timing data — native tables via streaming inserts"
}

# ── Locals: shared column definitions ─────────────────────────────────────────

locals {
  _meta_cols = [
    { name = "_key", type = "STRING", mode = "REQUIRED" },
    { name = "_id", type = "INT64", mode = "REQUIRED" },
  ]

  _session_meeting_cols = [
    { name = "meeting_key", type = "INT64", mode = "REQUIRED" },
    { name = "session_key", type = "INT64", mode = "REQUIRED" },
  ]

  _driver_col = [
    { name = "driver_number", type = "INT64", mode = "REQUIRED" },
  ]

  _date_col = [
    { name = "date", type = "TIMESTAMP", mode = "REQUIRED" },
  ]

  _date_nullable_col = [
    { name = "date", type = "TIMESTAMP", mode = "NULLABLE" },
  ]
}

# ── High-volume tables (partitioned by DATE(date)) ───────────────────────────

resource "google_bigquery_table" "car_data" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "car_data"
  project             = var.project_id
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "date"
  }
  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, local._date_col, [
    { name = "rpm", type = "INT64", mode = "NULLABLE" },
    { name = "speed", type = "INT64", mode = "NULLABLE" },
    { name = "n_gear", type = "INT64", mode = "NULLABLE" },
    { name = "throttle", type = "INT64", mode = "NULLABLE" },
    { name = "brake", type = "INT64", mode = "NULLABLE" },
    { name = "drs", type = "INT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "location" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "location"
  project             = var.project_id
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "date"
  }
  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, local._date_col, [
    { name = "x", type = "INT64", mode = "NULLABLE" },
    { name = "y", type = "INT64", mode = "NULLABLE" },
    { name = "z", type = "INT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "position" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "position"
  project             = var.project_id
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "date"
  }
  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, local._date_col, [
    { name = "position", type = "INT64", mode = "REQUIRED" },
  ]))
}

resource "google_bigquery_table" "intervals" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "intervals"
  project             = var.project_id
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "date"
  }
  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, [
    { name = "gap_to_leader", type = "STRING", mode = "NULLABLE", description = "Seconds behind leader (float) or lap offset string" },
    { name = "interval", type = "STRING", mode = "NULLABLE", description = "Seconds behind car ahead (float) or lap offset string" },
    { name = "date", type = "TIMESTAMP", mode = "REQUIRED" },
  ]))
}

# ── Medium-volume tables ──────────────────────────────────────────────────────

resource "google_bigquery_table" "laps" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "laps"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, [
    { name = "lap_number", type = "INT64", mode = "REQUIRED" },
    { name = "date_start", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "duration_sector_1", type = "FLOAT64", mode = "NULLABLE" },
    { name = "duration_sector_2", type = "FLOAT64", mode = "NULLABLE" },
    { name = "duration_sector_3", type = "FLOAT64", mode = "NULLABLE" },
    { name = "i1_speed", type = "INT64", mode = "NULLABLE" },
    { name = "i2_speed", type = "INT64", mode = "NULLABLE" },
    { name = "is_pit_out_lap", type = "BOOL", mode = "NULLABLE" },
    { name = "lap_duration", type = "FLOAT64", mode = "NULLABLE" },
    { name = "segments_sector_1", type = "STRING", mode = "NULLABLE", description = "JSON array of segment status ints" },
    { name = "segments_sector_2", type = "STRING", mode = "NULLABLE", description = "JSON array of segment status ints" },
    { name = "segments_sector_3", type = "STRING", mode = "NULLABLE", description = "JSON array of segment status ints" },
    { name = "st_speed", type = "INT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "stints" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "stints"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, [
    { name = "stint_number", type = "INT64", mode = "REQUIRED" },
    { name = "driver_number", type = "INT64", mode = "REQUIRED" },
    { name = "lap_start", type = "INT64", mode = "REQUIRED" },
    { name = "lap_end", type = "INT64", mode = "REQUIRED" },
    { name = "compound", type = "STRING", mode = "NULLABLE" },
    { name = "tyre_age_at_start", type = "INT64", mode = "NULLABLE" },
    { name = "_date_start_last_lap", type = "TIMESTAMP", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "weather" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "weather"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._date_col, [
    { name = "air_temperature", type = "FLOAT64", mode = "REQUIRED" },
    { name = "humidity", type = "FLOAT64", mode = "REQUIRED" },
    { name = "pressure", type = "FLOAT64", mode = "REQUIRED" },
    { name = "rainfall", type = "INT64", mode = "REQUIRED" },
    { name = "track_temperature", type = "FLOAT64", mode = "REQUIRED" },
    { name = "wind_direction", type = "INT64", mode = "REQUIRED" },
    { name = "wind_speed", type = "FLOAT64", mode = "REQUIRED" },
  ]))
}

# ── Low-volume tables ─────────────────────────────────────────────────────────

resource "google_bigquery_table" "pit" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "pit"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, [
    { name = "lap_number", type = "INT64", mode = "REQUIRED" },
    { name = "driver_number", type = "INT64", mode = "REQUIRED" },
    { name = "date", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "pit_duration", type = "FLOAT64", mode = "NULLABLE" },
    { name = "lane_duration", type = "FLOAT64", mode = "NULLABLE" },
    { name = "stop_duration", type = "FLOAT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "race_control" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "race_control"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, [
    { name = "date", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "driver_number", type = "INT64", mode = "NULLABLE" },
    { name = "lap_number", type = "INT64", mode = "NULLABLE" },
    { name = "category", type = "STRING", mode = "NULLABLE" },
    { name = "flag", type = "STRING", mode = "NULLABLE" },
    { name = "scope", type = "STRING", mode = "NULLABLE" },
    { name = "sector", type = "INT64", mode = "NULLABLE" },
    { name = "qualifying_phase", type = "INT64", mode = "NULLABLE" },
    { name = "message", type = "STRING", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "team_radio" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "team_radio"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key", "driver_number"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, [
    { name = "date", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "recording_url", type = "STRING", mode = "REQUIRED" },
  ]))
}

resource "google_bigquery_table" "drivers" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "drivers"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, [
    { name = "driver_number", type = "INT64", mode = "NULLABLE" },
    { name = "broadcast_name", type = "STRING", mode = "NULLABLE" },
    { name = "full_name", type = "STRING", mode = "NULLABLE" },
    { name = "name_acronym", type = "STRING", mode = "NULLABLE" },
    { name = "team_name", type = "STRING", mode = "NULLABLE" },
    { name = "team_colour", type = "STRING", mode = "NULLABLE" },
    { name = "first_name", type = "STRING", mode = "NULLABLE" },
    { name = "last_name", type = "STRING", mode = "NULLABLE" },
    { name = "headshot_url", type = "STRING", mode = "NULLABLE" },
    { name = "country_code", type = "STRING", mode = "NULLABLE" },
    { name = "_index", type = "INT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "championship_drivers" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "championship_drivers"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, local._driver_col, [
    { name = "position_start", type = "INT64", mode = "NULLABLE" },
    { name = "position_current", type = "INT64", mode = "NULLABLE" },
    { name = "points_start", type = "FLOAT64", mode = "NULLABLE" },
    { name = "points_current", type = "FLOAT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "championship_teams" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "championship_teams"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, [
    { name = "team_name", type = "STRING", mode = "NULLABLE" },
    { name = "_team_key", type = "STRING", mode = "REQUIRED" },
    { name = "position_start", type = "INT64", mode = "NULLABLE" },
    { name = "position_current", type = "INT64", mode = "NULLABLE" },
    { name = "points_start", type = "FLOAT64", mode = "NULLABLE" },
    { name = "points_current", type = "FLOAT64", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "overtakes" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "overtakes"
  project             = var.project_id
  deletion_protection = false

  clustering = ["session_key"]

  schema = jsonencode(concat(local._meta_cols, local._session_meeting_cols, [
    { name = "overtaking_driver_number", type = "INT64", mode = "REQUIRED" },
    { name = "overtaken_driver_number", type = "INT64", mode = "REQUIRED" },
    { name = "date", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "position", type = "INT64", mode = "REQUIRED" },
  ]))
}

# ── Reference/metadata tables ─────────────────────────────────────────────────

resource "google_bigquery_table" "sessions" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "sessions"
  project             = var.project_id
  deletion_protection = false

  schema = jsonencode(concat(local._meta_cols, [
    { name = "session_key", type = "INT64", mode = "REQUIRED" },
    { name = "session_type", type = "STRING", mode = "NULLABLE" },
    { name = "session_name", type = "STRING", mode = "NULLABLE" },
    { name = "date_start", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "date_end", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "meeting_key", type = "INT64", mode = "NULLABLE" },
    { name = "circuit_key", type = "INT64", mode = "NULLABLE" },
    { name = "circuit_short_name", type = "STRING", mode = "NULLABLE" },
    { name = "country_key", type = "INT64", mode = "NULLABLE" },
    { name = "country_code", type = "STRING", mode = "NULLABLE" },
    { name = "country_name", type = "STRING", mode = "NULLABLE" },
    { name = "location", type = "STRING", mode = "NULLABLE" },
    { name = "gmt_offset", type = "STRING", mode = "NULLABLE" },
    { name = "year", type = "INT64", mode = "NULLABLE" },
    { name = "is_cancelled", type = "BOOL", mode = "NULLABLE" },
    { name = "_path", type = "STRING", mode = "NULLABLE" },
  ]))
}

resource "google_bigquery_table" "meetings" {
  dataset_id          = google_bigquery_dataset.streaming.dataset_id
  table_id            = "meetings"
  project             = var.project_id
  deletion_protection = false

  schema = jsonencode(concat(local._meta_cols, [
    { name = "meeting_key", type = "INT64", mode = "REQUIRED" },
    { name = "meeting_name", type = "STRING", mode = "NULLABLE" },
    { name = "meeting_official_name", type = "STRING", mode = "NULLABLE" },
    { name = "location", type = "STRING", mode = "NULLABLE" },
    { name = "country_key", type = "INT64", mode = "NULLABLE" },
    { name = "country_code", type = "STRING", mode = "NULLABLE" },
    { name = "country_name", type = "STRING", mode = "NULLABLE" },
    { name = "country_flag", type = "STRING", mode = "NULLABLE" },
    { name = "circuit_key", type = "INT64", mode = "NULLABLE" },
    { name = "circuit_short_name", type = "STRING", mode = "NULLABLE" },
    { name = "circuit_type", type = "STRING", mode = "NULLABLE" },
    { name = "circuit_info_url", type = "STRING", mode = "NULLABLE" },
    { name = "circuit_image", type = "STRING", mode = "NULLABLE" },
    { name = "gmt_offset", type = "STRING", mode = "NULLABLE" },
    { name = "date_start", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "date_end", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "year", type = "INT64", mode = "NULLABLE" },
    { name = "is_cancelled", type = "BOOL", mode = "NULLABLE" },
  ]))
}
