#!/bin/bash
# Setup script for first OWNER account (K25)
# This script can only be run once per environment.
# Usage: ./scripts/setup-first-owner.sh <email> <password> <display_name>

set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <email> <password> <display_name>"
    echo "Password must be at least 10 characters."
    exit 1
fi

EMAIL="$1"
PASSWORD="$2"
DISPLAY_NAME="$3"

echo "Setting up first owner: $EMAIL"

psql "$SUPABASE_DB_POOLER_URL" -c "
SELECT setup_first_owner('$EMAIL', '$PASSWORD', '$DISPLAY_NAME');
"

echo "First owner setup complete."
