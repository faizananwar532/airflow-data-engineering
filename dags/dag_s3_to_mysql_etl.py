# This dag lets us read the data from S3 and load it into MySQL
# To test the functionality of s3 with mysql via Airflow.

#!/usr/bin/env python3

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
import pandas as pd
import boto3
import io
import mysql.connector
from mysql.connector import Error

# Define default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# AWS credentials - in production, use Airflow connections or secrets
AWS_ACCESS_KEY = "AWS_ACCESS_KEY"
AWS_SECRET_KEY = "AWS_SECRET_KEY"
REGION = "AWS_REGION"
S3_BUCKET = "AWS_S3_DAGS_BUCKET"

# MySQL connection parameters
MYSQL_HOST = "MYSQL_HOST"
MYSQL_USER = "myuser"
MYSQL_PASSWORD = "mypassword"
MYSQL_DB = "mydb"

# Define the functions for our ETL process
def extract_from_s3(**kwargs):
    """Extract data from S3 - in this example we'll generate mock data"""
    print("Extracting data from S3...")
    
    # For demonstration, let's create mock employee data
    # In a real scenario, you would fetch this from an actual S3 file
    data = {
        'employee_id': [1, 2, 3, 4, 5],
        'name': ['John Doe', 'Jane Smith', 'Bob Johnson', 'Alice Brown', 'Charlie Davis'],
        'department': ['Engineering', 'Marketing', 'HR', 'Engineering', 'Finance'],
        'salary': [85000, 75000, 65000, 90000, 95000]
    }
    
    # Create a DataFrame
    df = pd.DataFrame(data)
    print(f"Extracted {len(df)} records")
    
    # In a real scenario, you would do something like:
    # s3_client = boto3.client('s3', aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    # obj = s3_client.get_object(Bucket=S3_BUCKET, Key='data/employees.csv')
    # df = pd.read_csv(io.BytesIO(obj['Body'].read()))
    
    # Push the DataFrame to XCom so the next task can use it
    kwargs['ti'].xcom_push(key='employee_data', value=df.to_dict())
    return "Data extraction complete"

def transform_data(**kwargs):
    """Transform the extracted data"""
    print("Transforming data...")
    
    # Pull the DataFrame from XCom
    ti = kwargs['ti']
    data_dict = ti.xcom_pull(task_ids='extract_data', key='employee_data')
    df = pd.DataFrame(data_dict)
    
    # Perform transformations
    # 1. Calculate bonus (10% of salary)
    df['bonus'] = df['salary'] * 0.10
    
    # 2. Calculate total compensation
    df['total_compensation'] = df['salary'] + df['bonus']
    
    # 3. Add a performance category based on salary
    def get_performance_category(salary):
        if salary >= 90000:
            return 'High'
        elif salary >= 75000:
            return 'Medium'
        else:
            return 'Standard'
    
    df['performance_category'] = df['salary'].apply(get_performance_category)
    
    print("Transformation complete")
    print(df.head())
    
    # Push the transformed DataFrame to XCom
    kwargs['ti'].xcom_push(key='transformed_data', value=df.to_dict())
    return "Data transformation complete"

def load_to_mysql(**kwargs):
    """Load the transformed data to MySQL"""
    print("Loading data to MySQL...")
    
    # Pull the transformed DataFrame from XCom
    ti = kwargs['ti']
    data_dict = ti.xcom_pull(task_ids='transform_data', key='transformed_data')
    df = pd.DataFrame(data_dict)
    
    try:
        # Connect to MySQL
        conn = mysql.connector.connect(
            host=MYSQL_HOST,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DB
        )
        
        if conn.is_connected():
            cursor = conn.cursor()
            
            # Create table if it doesn't exist
            create_table_query = """
            CREATE TABLE IF NOT EXISTS employee_compensation (
                employee_id INT PRIMARY KEY,
                name VARCHAR(100),
                department VARCHAR(50),
                salary DECIMAL(10, 2),
                bonus DECIMAL(10, 2),
                total_compensation DECIMAL(10, 2),
                performance_category VARCHAR(20),
                processed_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
            cursor.execute(create_table_query)
            
            # Insert data row by row
            for _, row in df.iterrows():
                insert_query = """
                INSERT INTO employee_compensation 
                (employee_id, name, department, salary, bonus, total_compensation, performance_category)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                name = VALUES(name),
                department = VALUES(department),
                salary = VALUES(salary),
                bonus = VALUES(bonus),
                total_compensation = VALUES(total_compensation),
                performance_category = VALUES(performance_category),
                processed_date = CURRENT_TIMESTAMP
                """
                values = (
                    int(row['employee_id']),
                    row['name'],
                    row['department'],
                    float(row['salary']),
                    float(row['bonus']),
                    float(row['total_compensation']),
                    row['performance_category']
                )
                cursor.execute(insert_query, values)
            
            # Commit the transaction
            conn.commit()
            print(f"Successfully loaded {len(df)} records to MySQL")
            
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return f"Failed to load data: {e}"
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
            print("MySQL connection closed")
    
    return "Data loading complete"

# Create the DAG
with DAG(
    's3_to_mysql_etl',
    default_args=default_args,
    description='ETL DAG that extracts data from S3, transforms it, and loads to MySQL',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['etl', 'mysql', 's3'],
) as dag:
    
    # Define the tasks
    extract_task = PythonOperator(
        task_id='extract_data',
        python_callable=extract_from_s3,
        provide_context=True,
    )
    
    transform_task = PythonOperator(
        task_id='transform_data',
        python_callable=transform_data,
        provide_context=True,
    )
    
    load_task = PythonOperator(
        task_id='load_to_mysql',
        python_callable=load_to_mysql,
        provide_context=True,
    )
    
    # Set task dependencies
    extract_task >> transform_task >> load_task 