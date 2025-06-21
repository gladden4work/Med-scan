# MediScan Database Setup

This directory contains the SQL files needed to set up the MediScan application database in Supabase.

## Simplified Setup

We've consolidated all the database setup into a single file for easier deployment:

- `mediscan_setup.sql` - Complete database setup in one file

## How to Use

1. Log in to your Supabase project
2. Navigate to the SQL Editor
3. Copy and paste the contents of `mediscan_setup.sql`
4. Execute the query to set up all tables, indexes, and security policies

## What's Included

The consolidated setup file contains:

1. **Table Creation**
   - `scan_history` - Stores user scan records
   - `user_medications` - Stores user saved medications

2. **Performance Indexes**
   - User ID indexes
   - Creation date indexes
   - Soft delete filtering indexes

3. **Row Level Security (RLS)**
   - User-specific data access policies
   - Proper security for multi-tenant data

4. **Triggers and Functions**
   - Automatic `updated_at` timestamp management
   - Soft delete functionality

5. **Permissions**
   - Proper grants for authenticated users

## Archive Files

The following files are kept for reference but are no longer needed for setup:

- `scan_history_table.sql` - Original scan history table creation
- `user_medications_table.sql` - Original user medications table creation
- `soft_delete_migration.sql` - Migration for adding soft delete functionality
- `soft_delete_functions.sql` - Functions for soft delete operations
- `update_rls_policies.sql` - Updates to RLS policies for better performance
- `reset_rls_policies.sql` - Complete reset of RLS policies

## Important Notes

- The setup uses Supabase's `auth.uid()` function for user identification
- All tables include soft delete functionality with `is_deleted` column
- RLS policies automatically filter out soft-deleted records
- Specialized functions with `SECURITY DEFINER` handle soft deletes safely 