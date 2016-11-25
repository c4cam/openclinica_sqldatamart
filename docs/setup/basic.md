# Basic Setup


## Dependencies
- PostgreSQL 9.3+


## Summary
On OC server:
- [Create an OC Postgres Login Role for OCDM](#create-an-oc-postgres-login-role-for-ocdm)
- [Update the OC postgres Host Based Authentication file](#update-the-oc-postgres-host-based-authentication-file)

On OCDM server:
- [Install PostgreSQL on OCDM](#install-postgresql-on-ocdm)
- [Create postgres OpenClinica Report Database](#create-postgres-openclinica-report-database)


## Steps to Complete on OC Server


### Create an OC Postgres Login Role for OCDM
In order to retrieve data, OCDM needs to be able to connect to OC, which 
requires a login user on the OC postgres server. This server to server 
connection requires password authentication, as it cannot use SSPI.

- Log in to OC postgres as a superuser and run the following commands to create
  a role with the necessary permissions:

```sql
CREATE ROLE "openclinica_select"
    NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE openclinica to openclinica_select;
GRANT USAGE ON SCHEMA public to openclinica_select;
```

- For postgres 9.0+, the run the following command:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public to openclinica_select;
```

- For postgres <9.0, run the following commands:

```sql
CREATE FUNCTION public.grant_select_on_all_tables_in_schema()
RETURNS VOID AS
$$DECLARE r record;
BEGIN
FOR r IN
    SELECT 'GRANT SELECT ON ' || relname || ' TO openclinica_select;' as gnt
    FROM pg_class JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE nspname = 'public' AND relkind IN ('r', 'v')
LOOP
    EXECUTE r.gnt;
END LOOP;
END;$$
LANGUAGE plpgsql VOLATILE;
SELECT public.grant_select_on_all_tables_in_schema();
DROP FUNCTION public.grant_select_on_all_tables_in_schema();
```

- Run the following commands to create a login role for the connection:

```sql
CREATE ROLE ocdm_fdw WITH LOGIN ENCRYPTED PASSWORD 'aGoodPassword'
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
GRANT openclinica_select TO ocdm_fdw;
```


### Update the OC postgres Host Based Authentication file
The Host Based Authentication file (pg_hba.conf) can be found in the postgres
data directory.
- Add a row to allow connections to OC from OCDM (in addition to existing local
  rows, ensure there is no conflict):

```
# TYPE  DATABASE        USER                 ADDRESS                 METHOD
host openclinica     ocdm_fdw             ocdmIPAddress/32         md5
```


## Steps to Complete on OCDM Server


### Install PostgreSQL on OCDM
- Use the Windows installer from postgresql.org.
- Complete the optional installation of pgAgent job scheduler
- Choose a good password for the postgres superuser and keep it secret.

There seemed to be a bug in the postgres installation when using double quote 
characters in the password. The *data* directory would fail to be created. Use 
lots of other characters instead.

For the basic setup it is assumed that the pg_agent service will run as the 
postgres superuser. If this is not desired, see the advanced setup.


### Create postgres OpenClinica Report Database
The creation of the database is handled by a package of scripts called 
*sqldatamart*. A batch file accepts settings for the database which are 
substituted into the scripts where necessary. The setup needs to be run as a 
superuser because it requires a 'CREATE EXTENSION' statement for the foreign 
data wrapper, which can only be executed by superusers.

The build process is controlled by the *dm_build_commands* script. The script 
includes variables which must be provided to psql during the running of the 
script. The provided *setup_sqldatamart* Windows batch file sets and passes in 
the variables. 

- Edit the *setup_sqldatamart* bat file *set* statements to match the values 
  relevant to the environment.
- Run the *setup_sqldatamart* bat file.