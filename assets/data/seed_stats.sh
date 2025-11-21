#!/usr/bin/env bash
set -euo pipefail

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 is required on PATH" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /absolute/path/to/app.db" >&2
  exit 1
fi

DB="$1"

# --- Config ---
START_MS=1761951600000 
DAYS=30
MS_PER_DAY=86400000

# Topics provided by you (exact spellings kept)
TOPICS=(
  "Principes et valeurs"
  "Droits et devoirs"
  "Société et vie"
  "Histoire et culture"
  "Institutions et politique"
)

# Minimal synthetic series to satisfy FK in series_stats
SERIES_IDS=(1001 1002 1003)

# --- Helpers ---
rand_int() { # inclusive range
  local min=$1 max=$2
  echo $(( RANDOM % (max - min + 1) + min ))
}
pick_series_id() {
  local idx
  idx=$(rand_int 0 $((${#SERIES_IDS[@]} - 1)))
  echo "${SERIES_IDS[$idx]}"
}

# Ensure 'series' has a few rows we can reference (no reads)
sqlite3 -batch "$DB" <<'SQL'
PRAGMA foreign_keys=ON;
BEGIN;
INSERT OR IGNORE INTO series(id, type, position) VALUES (1001, 0, 1);
INSERT OR IGNORE INTO series(id, type, position) VALUES (1002, 1, 2);
INSERT OR IGNORE INTO series(id, type, position) VALUES (1003, 0, 3);
COMMIT;
SQL

# Clear the window so the script is idempotent
END_MS=$(( START_MS + (DAYS-1)*MS_PER_DAY ))
sqlite3 -batch "$DB" <<SQL
PRAGMA foreign_keys=ON;
BEGIN;
DELETE FROM time_spent_stats WHERE date BETWEEN $START_MS AND $END_MS;
DELETE FROM answers_stats     WHERE date BETWEEN $START_MS AND $END_MS;
DELETE FROM series_stats      WHERE date BETWEEN $START_MS AND $END_MS;
COMMIT;
SQL

echo "Seeding $DAYS day(s) from $START_MS to $END_MS into $DB"

for (( i=0; i< DAYS; i++ )); do
  DAY_MS=$(( START_MS + i*MS_PER_DAY ))

  # time_spent_stats: 5–90 minutes
  TIME_SPENT=$(rand_int 300 5400)
  sqlite3 -batch "$DB" <<SQL
PRAGMA foreign_keys=ON;
BEGIN;
INSERT INTO time_spent_stats(date, time_spent_secs)
VALUES($DAY_MS, $TIME_SPENT)
ON CONFLICT(date) DO UPDATE SET time_spent_secs=excluded.time_spent_secs;
COMMIT;
SQL

  # answers_stats: one row per topic/day
  for topic in "${TOPICS[@]}"; do
    correct=$(rand_int 5 25)
    incorrect=$(rand_int 0 10)
    sqlite3 -batch "$DB" <<SQL
PRAGMA foreign_keys=ON;
BEGIN;
INSERT INTO answers_stats(date, topic, correct_count, incorrect_count)
VALUES($DAY_MS, '$topic', $correct, $incorrect)
ON CONFLICT(date, topic) DO UPDATE
SET correct_count=excluded.correct_count,
    incorrect_count=excluded.incorrect_count;
COMMIT;
SQL
  done

  # series_stats: 1–3 sessions/day using synthetic series
  sessions=$(rand_int 1 3)
  for (( s=0; s<sessions; s++ )); do
    sid=$(pick_series_id)
    score_int=$(rand_int 40 100)     # 40.0–100.0
    duration=$(rand_int 120 2400)      # 2–40 minutes
    sqlite3 -batch "$DB" <<SQL
PRAGMA foreign_keys=ON;
BEGIN;
INSERT INTO series_stats(date, series_id, score, duration_secs)
VALUES($DAY_MS, $sid, $score_int/100.0, $duration);
COMMIT;
SQL
  done

  echo "  • seeded day $((i+1)) at $DAY_MS"
done

echo "✅ Done."
