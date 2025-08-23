#!/bin/bash

# Script to clean up MySQL database for Airflow
set -e

echo "===== Cleaning MySQL Database for Airflow ====="

# MySQL connection details
MYSQL_HOST="MYSQL_HOST"
MYSQL_PORT="3306"
MYSQL_USER="myuser"
MYSQL_PASSWORD="mypassword"
MYSQL_DB="mydb"

# Path to SQL cleanup script
SQL_SCRIPT="$(dirname "$0")/cleanup-mysql-db.sql"

# Check if the SQL script exists
if [ ! -f "$SQL_SCRIPT" ]; then
  echo "Error: SQL script not found at $SQL_SCRIPT"
  exit 1
fi

echo "Executing SQL cleanup script on MySQL database..."
mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$SQL_SCRIPT"

echo "MySQL database cleanup completed successfully."
echo "You can now run reset-airflow.sh to redeploy Airflow with a clean database." 