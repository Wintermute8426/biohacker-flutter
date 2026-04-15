#!/bin/bash
# Run migration via Supabase API
# Credentials must be set via environment variables — never hardcode them here.

SQL_FILE="lib/migrations/seed_community_protocols.sql"

echo "Applying migration: $SQL_FILE"
echo "This needs to be run via Supabase SQL Editor or psql"
echo ""
echo "INSTRUCTIONS:"
echo "1. Go to: https://supabase.com/dashboard/project/<your-project>/editor"
echo "2. Click 'SQL Editor' → 'New query'"
echo "3. Copy and paste the contents of: $SQL_FILE"
echo "4. Click 'Run'"
echo ""
echo "Or set DB_PASSWORD env var and run:"
echo "psql \"postgresql://postgres.<project-ref>:\$DB_PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres\" < $SQL_FILE"

