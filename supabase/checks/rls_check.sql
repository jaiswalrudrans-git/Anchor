-- =============================================================================
-- ANCHOR: RLS & BACKEND HYGIENE AUDIT SCRIPT
-- =============================================================================
-- Read-only verification query for Supabase SQL Editor.
-- Flags any public table where Row-Level Security (RLS) is disabled
-- or where no active security policies are defined.

-- 1. Check Tables Missing RLS
SELECT
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT IN ('schema_migrations')
  AND rowsecurity = false;

-- 2. Check Tables Missing Policies
SELECT
    t.schemaname,
    t.tablename,
    count(p.policyname) AS policy_count
FROM pg_tables t
LEFT JOIN pg_policies p
    ON t.schemaname = p.schemaname
    AND t.tablename = p.tablename
WHERE t.schemaname = 'public'
  AND t.tablename NOT IN ('schema_migrations')
GROUP BY t.schemaname, t.tablename
HAVING count(p.policyname) = 0;

-- 3. Detailed List of All Active Policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4. Storage Bucket Check
SELECT
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE name = 'academic_vault';

-- 5. Storage Policies Check
SELECT
    policyname,
    tablename,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects';
