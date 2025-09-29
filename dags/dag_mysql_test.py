"""
MySQL Connection Test DAG

This DAG tests the MySQL connection in Airflow by:
1. Testing the connection
2. Running a simple query
3. Logging the results

Author: Airflow Data Engineering
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.mysql.operators.mysql import MySqlOperator
from airflow.providers.mysql.hooks.mysql import MySqlHook
import logging

# Default arguments
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# DAG definition
dag = DAG(
    'mysql_connection_test',
    default_args=default_args,
    description='Test MySQL connection in Airflow',
    schedule_interval=timedelta(days=1),
    catchup=False,
    tags=['mysql', 'test', 'connection'],
)

def test_mysql_connection():
    """
    Test MySQL connection and run a simple query
    """
    try:
        # Get MySQL connection
        mysql_hook = MySqlHook(mysql_conn_id='mysql')
        
        # Test connection
        logging.info("Testing MySQL connection...")
        conn = mysql_hook.get_conn()
        cursor = conn.cursor()
        
        # Run a simple query
        cursor.execute("SELECT VERSION(), NOW()")
        result = cursor.fetchone()
        
        logging.info(f"MySQL Version: {result[0]}")
        logging.info(f"Current Time: {result[1]}")
        
        # Test database access
        cursor.execute("SHOW DATABASES")
        databases = cursor.fetchall()
        logging.info(f"Available databases: {[db[0] for db in databases]}")
        
        cursor.close()
        conn.close()
        
        logging.info("✅ MySQL connection test successful!")
        return "MySQL connection test completed successfully"
        
    except Exception as e:
        logging.error(f"❌ MySQL connection test failed: {str(e)}")
        raise

def test_mysql_tables():
    """
    Test MySQL tables and show Airflow tables
    """
    try:
        mysql_hook = MySqlHook(mysql_conn_id='mysql')
        conn = mysql_hook.get_conn()
        cursor = conn.cursor()
        
        # Show tables in the database
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        
        logging.info(f"Tables in database: {[table[0] for table in tables]}")
        
        # Check if Airflow tables exist
        airflow_tables = ['dag', 'dag_run', 'task_instance', 'connection']
        existing_tables = [table[0] for table in tables]
        
        for table in airflow_tables:
            if table in existing_tables:
                logging.info(f"✅ Airflow table '{table}' exists")
            else:
                logging.info(f"⚠️  Airflow table '{table}' not found")
        
        cursor.close()
        conn.close()
        
        logging.info("✅ MySQL tables test completed!")
        return "MySQL tables test completed successfully"
        
    except Exception as e:
        logging.error(f"❌ MySQL tables test failed: {str(e)}")
        raise

# Task definitions
test_connection_task = PythonOperator(
    task_id='test_mysql_connection',
    python_callable=test_mysql_connection,
    dag=dag,
)

test_tables_task = PythonOperator(
    task_id='test_mysql_tables',
    python_callable=test_mysql_tables,
    dag=dag,
)

# Simple SQL task
sql_test_task = MySqlOperator(
    task_id='sql_test',
    mysql_conn_id='mysql',
    sql="SELECT 'MySQL connection working!' as message, NOW() as timestamp",
    dag=dag,
)

# Task dependencies
test_connection_task >> test_tables_task >> sql_test_task
