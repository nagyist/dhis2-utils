--
-- Function for cancelling slow queries generated by DHIS 2
--
-- Excludes queries from psql, pg_dump (backup), PostgreSQL maintenance and DHIS 2 analytics table generation
--
-- Adjust username filter to environment, set to 'dhis' by default
--
-- This script could alternatively use the `pg_terminate_backend`
--
-- Execute as SQL statement with $ select dhis_cancel_slow_queries();
--
-- Execute with psql with $ psql -d database -c "select dhis_cancel_slow_queries();"
--
-- Create cron job to run every minute during day
--
-- * 8-23 * * *   /bin/bash -c 'psql -d database -c "select dhis_cancel_slow_queries();"'
--

-- Create view

create or replace view dhis_slow_queries as
select * from pg_catalog.pg_stat_activity
where (now() - pg_stat_activity.query_start) > interval '2 minutes'
and usename = 'dhis'
and application_name not in ('psql', 'pg_dump')
and query ilike 'select%'
and query !~* ('pg_catalog|information_schema|pg_temp|pg_toast');

-- Create function

create or replace function dhis_cancel_slow_queries()
returns integer as $$
declare
    q record;
    c integer := 0;
begin
    for q in select * from dhis_slow_queries
    loop
        raise notice 'Cancelling query with PID: %', q.pid;
        perform pg_cancel_backend(q.pid);
        c := c + 1;
    end loop;
    return c;
end;
$$ language plpgsql;
