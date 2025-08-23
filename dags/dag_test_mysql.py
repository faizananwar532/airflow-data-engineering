# This DAG tests the MySQL connection and executes a simple query.

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import mysql.connector

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def test_mysql_connection(**kwargs):
    """Test MySQL connection and execute a simple query"""
    conn = mysql.connector.connect(
        host='MYSQL_HOST',
        user='myuser',
        password='mypassword',
        database='mydb'
    )
    
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM connection")
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    
    print(f"Number of connections in the database: {result[0]}")
    return result[0]

with DAG(
    'test_mysql_connection',
    default_args=default_args,
    description='A simple DAG to test MySQL connection',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['test', 'mysql'],
) as dag:

    test_task = PythonOperator(
        task_id='test_mysql_connection',
        python_callable=test_mysql_connection,
    ) 