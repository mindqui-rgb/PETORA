#!/bin/bash
# Setup script for first OWNER account (K25)
# This script can only be run once per environment.
# Usage: ./scripts/setup-first-owner.sh <email> <display_name>

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <email> <display_name>" >&2
    exit 1
fi

EMAIL="$1"
DISPLAY_NAME="$2"

read -r -s -p "Kata sandi pemilik (minimal 10 karakter): " PASSWORD
printf '\n'
if [ "${#PASSWORD}" -lt 10 ]; then
    echo "Kata sandi minimal 10 karakter." >&2
    exit 1
fi

sql_literal() {
    local escaped_value=${1//\'/\'\'}
    printf "'%s'" "$escaped_value"
}

SQL_EMAIL=$(sql_literal "$EMAIL")
SQL_PASSWORD=$(sql_literal "$PASSWORD")
SQL_DISPLAY_NAME=$(sql_literal "$DISPLAY_NAME")
unset PASSWORD

psql -v ON_ERROR_STOP=1 "${SUPABASE_DB_POOLER_URL:?SUPABASE_DB_POOLER_URL is required}" <<SQL
SELECT public.setup_first_owner($SQL_EMAIL, $SQL_PASSWORD, $SQL_DISPLAY_NAME);
SQL
unset SQL_PASSWORD

echo "Pemilik pertama berhasil disiapkan."
