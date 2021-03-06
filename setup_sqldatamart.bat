:: time script started running
set start_time=%time%
:: ocdm psql executable path
set "psql=C:\Program Files\PostgreSQL\9.3\bin\psql"
:: ocdm ip address
set PGHOST=127.0.0.1
:: ocdm port
set PGPORT=myOCDM_Port
:: ocdm superuser
set PGUSER=postgres
:: ocdm superuser password
set PGPASSWORD=thePostgresSuperuserPassword
:: ocdm datamart admin role name, owns all objects
set datamart_admin_role_name=dm_admin
:: oc host name
set foreign_server_host_name=myOCDM_FQDN
:: oc host ip address
set foreign_server_host_address=myOCDM_IP
:: oc port
set foreign_server_port=myOC_Port
:: oc database name
set foreign_server_database=myOC_DBname
:: oc foreign server connection user
set foreign_server_user_name=theForeignServer_ocdm_fdw_UserName
:: oc foreign server connection user password
set foreign_server_user_password=theForeignServer_ocdm_fdw_UserPassword
:: oc schema name, default: public
set foreign_server_openclinica_schema_name=myOC_SchemaName
:: extra kwargs for the foreign server connection. comment out if this line if not used.
set "foreign_server_data_wrapper_kwargs=, sslmode 'verify-full', sslrootcert 'root.crt'"
:: path to this batch file
set "scripts_path=C:\Users\myUserName\Desktop\sqldatamart"

:: uncomment these two lines to remove the database if re-running the build
::"%psql%" -q  -d postgres -c "DROP DATABASE openclinica_fdw_db;" -P pager
::"%psql%" -q  -d postgres -c "DROP USER dm_admin;" -P pager

:: create the database
"%psql%" -q  -d postgres -c "CREATE DATABASE openclinica_fdw_db;" -P pager
:: create a schema for the foreign server objects
"%psql%" -q  -d openclinica_fdw_db -c "CREATE SCHEMA openclinica_fdw;" -P pager
:: set search path so not everything requires "openclinica_fdw" prefix
"%psql%" -q  -d openclinica_fdw_db -c "ALTER DATABASE openclinica_fdw_db SET search_path = 'openclinica_fdw';"
:: recurse scripts directory for .sql files and execute each one
for /r "%scripts_path%"\scripts %%F in (*.sql) do (
    (
     "%psql%" -q  -d openclinica_fdw_db -f %%F -P pager
    )
)
:: run the main build script with all the required variables
"%psql%" -q  -d openclinica_fdw_db -f "%scripts_path%"\dm_build_commands.sql ^
    -v datamart_admin_role_name=%datamart_admin_role_name% ^
    -v datamart_admin_role_name_string=^'%datamart_admin_role_name%^' ^
    -v foreign_server_host_name=^'%foreign_server_host_name%^' ^
    -v foreign_server_host_address=^'%foreign_server_host_address%^' ^
    -v foreign_server_port=^'%foreign_server_port%^' ^
    -v foreign_server_database=^'%foreign_server_database%^' ^
    -v foreign_server_user_name=^'%foreign_server_user_name%^' ^
    -v foreign_server_user_password=^'%foreign_server_user_password%^' ^
    -v foreign_server_openclinica_schema_name=^'%foreign_server_openclinica_schema_name%^' ^
    -v foreign_server_data_wrapper_kwargs="%foreign_server_data_wrapper_kwargs%" ^
    -P pager
:: print the start time and the current time
echo %start_time% %time%
pause