#!/bin/bash
# Run migration via Supabase API

SUPABASE_URL="https://dfiewtwbxqfrrmyiqhqo.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmaWV3dHdieHFmcnJteWlxaHFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ3MTYzNTQsImV4cCI6MjA1MDI5MjM1NH0.4VYr5nKHQnMDzG1tJ17D7M8VyiUv7nPBrXa1HN2zV3U"

SQL_FILE="lib/migrations/seed_community_protocols.sql"

echo "Applying migration: $SQL_FILE"
echo "This needs to be run via Supabase SQL Editor or psql"
echo ""
echo "INSTRUCTIONS:"
echo "1. Go to: https://supabase.com/dashboard/project/dfiewtwbxqfrrmyiqhqo/editor"
echo "2. Click 'SQL Editor' → 'New query'"
echo "3. Copy and paste the contents of: $SQL_FILE"
echo "4. Click 'Run'"
echo ""
echo "Or install psql and run:"
echo "psql 'postgresql://postgres.dfiewtwbxqfrrmyiqhqo:DKhjd89&D&67#@aws-0-us-east-1.pooler.supabase.com:6543/postgres' < $SQL_FILE"

