"""
GitHub MySQL ETL DAG
This DAG demonstrates an ETL process that:
1. Extracts data from a simulated source
2. Transforms the data
3. Loads it into MySQL database
4. Automatically syncs from GitHub to Airflow
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator

# Default arguments
default_args = {
    'owner': 'github-etl',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'github_mysql_etl_dag',
    default_args=default_args,
    description='ETL DAG synced from GitHub with MySQL integration',
    schedule_interval=timedelta(hours=6),  # Run every 6 hours
    catchup=False,
    tags=['github', 'mysql', 'etl', 'production'],
)

def extract_github_data(**kwargs):
    """Extract sample data (simulating GitHub API or file data)"""
    import json
    import random
    from datetime import datetime
    
    # Simulate extracting data from GitHub repositories or other sources
    sample_data = []
    
    # Generate sample GitHub repository data
    repo_names = ['data-pipeline', 'ml-models', 'web-app', 'analytics', 'monitoring']
    languages = ['Python', 'JavaScript', 'Go', 'Java', 'TypeScript']
    
    for i in range(10):
        repo_data = {
            'repo_id': i + 1,
            'repo_name': random.choice(repo_names) + f'-{i+1}',
            'language': random.choice(languages),
            'stars': random.randint(1, 1000),
            'forks': random.randint(0, 200),
            'issues': random.randint(0, 50),
            'created_date': datetime.now().strftime('%Y-%m-%d'),
            'last_updated': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }
        sample_data.append(repo_data)
    
    print(f"✅ Extracted {len(sample_data)} repository records")
    print("Sample data:", json.dumps(sample_data[:2], indent=2))
    
    # Store data for next task
    return sample_data

def transform_github_data(**kwargs):
    """Transform the extracted data"""
    # Get data from previous task
    ti = kwargs['ti']
    raw_data = ti.xcom_pull(task_ids='extract_github_data')
    
    if not raw_data:
        raise ValueError("No data received from extract task")
    
    transformed_data = []
    
    for repo in raw_data:
        # Calculate popularity score
        popularity_score = (repo['stars'] * 0.7) + (repo['forks'] * 0.3)
        
        # Categorize repository size
        if repo['stars'] > 500:
            size_category = 'Large'
        elif repo['stars'] > 100:
            size_category = 'Medium'
        else:
            size_category = 'Small'
        
        # Calculate activity score
        activity_score = max(0, 100 - repo['issues'])  # Fewer issues = higher activity score
        
        transformed_repo = {
            'repo_id': repo['repo_id'],
            'repo_name': repo['repo_name'],
            'language': repo['language'],
            'stars': repo['stars'],
            'forks': repo['forks'],
            'issues': repo['issues'],
            'popularity_score': round(popularity_score, 2),
            'size_category': size_category,
            'activity_score': activity_score,
            'created_date': repo['created_date'],
            'last_updated': repo['last_updated']
        }
        transformed_data.append(transformed_repo)
    
    print(f"✅ Transformed {len(transformed_data)} repository records")
    print("Transformation complete - added popularity_score, size_category, activity_score")
    
    return transformed_data

def load_to_mysql(**kwargs):
    """Load transformed data into MySQL"""
    import mysql.connector
    from mysql.connector import Error
    
    # Get transformed data
    ti = kwargs['ti']
    data = ti.xcom_pull(task_ids='transform_github_data')
    
    if not data:
        raise ValueError("No data received from transform task")
    
    try:
        # Connect to MySQL
        connection = mysql.connector.connect(
            host='54.167.107.216',
            database='mydb',
            user='myuser',
            password='mypassword',
            port=3306
        )
        
        if connection.is_connected():
            cursor = connection.cursor()
            print("✅ Connected to MySQL database")
            
            # Create table if it doesn't exist
            create_table_query = """
            CREATE TABLE IF NOT EXISTS github_repositories (
                repo_id INT PRIMARY KEY,
                repo_name VARCHAR(255) NOT NULL,
                language VARCHAR(100),
                stars INT DEFAULT 0,
                forks INT DEFAULT 0,
                issues INT DEFAULT 0,
                popularity_score DECIMAL(10,2),
                size_category VARCHAR(50),
                activity_score INT,
                created_date DATE,
                last_updated TIMESTAMP,
                etl_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
            """
            
            cursor.execute(create_table_query)
            print("✅ Table 'github_repositories' created/verified")
            
            # Insert data
            insert_query = """
            INSERT INTO github_repositories 
            (repo_id, repo_name, language, stars, forks, issues, 
             popularity_score, size_category, activity_score, created_date, last_updated)
            VALUES (%(repo_id)s, %(repo_name)s, %(language)s, %(stars)s, %(forks)s, %(issues)s,
                    %(popularity_score)s, %(size_category)s, %(activity_score)s, %(created_date)s, %(last_updated)s)
            ON DUPLICATE KEY UPDATE
            repo_name=VALUES(repo_name), language=VALUES(language), stars=VALUES(stars),
            forks=VALUES(forks), issues=VALUES(issues), popularity_score=VALUES(popularity_score),
            size_category=VALUES(size_category), activity_score=VALUES(activity_score),
            last_updated=VALUES(last_updated)
            """
            
            cursor.executemany(insert_query, data)
            connection.commit()
            
            print(f"✅ Successfully inserted/updated {cursor.rowcount} records")
            
            # Query and display results
            cursor.execute("SELECT COUNT(*) FROM github_repositories")
            total_count = cursor.fetchone()[0]
            print(f"📊 Total repositories in database: {total_count}")
            
            # Show sample of loaded data
            cursor.execute("""
                SELECT repo_name, language, stars, popularity_score, size_category 
                FROM github_repositories 
                ORDER BY popularity_score DESC 
                LIMIT 5
            """)
            
            results = cursor.fetchall()
            print("\n📈 Top 5 repositories by popularity:")
            for row in results:
                print(f"  - {row[0]} ({row[1]}) - {row[2]} stars, score: {row[3]}, size: {row[4]}")
            
            return f"Successfully loaded {len(data)} records to MySQL"
            
    except Error as e:
        print(f"❌ Error connecting to MySQL: {e}")
        raise
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()
            print("✅ MySQL connection closed")

def generate_report(**kwargs):
    """Generate a summary report"""
    import mysql.connector
    from mysql.connector import Error
    
    try:
        connection = mysql.connector.connect(
            host='54.167.107.216',
            database='mydb',
            user='myuser',
            password='mypassword',
            port=3306
        )
        
        if connection.is_connected():
            cursor = connection.cursor()
            
            # Generate summary statistics
            queries = {
                'total_repos': "SELECT COUNT(*) FROM github_repositories",
                'avg_stars': "SELECT AVG(stars) FROM github_repositories",
                'top_language': """
                    SELECT language, COUNT(*) as count 
                    FROM github_repositories 
                    GROUP BY language 
                    ORDER BY count DESC 
                    LIMIT 1
                """,
                'size_distribution': """
                    SELECT size_category, COUNT(*) as count 
                    FROM github_repositories 
                    GROUP BY size_category 
                    ORDER BY count DESC
                """
            }
            
            report = {}
            for key, query in queries.items():
                cursor.execute(query)
                if key == 'size_distribution':
                    report[key] = cursor.fetchall()
                else:
                    result = cursor.fetchone()
                    report[key] = result[0] if result else 0
            
            print("\n📊 GitHub Repositories ETL Report")
            print("=" * 40)
            print(f"Total Repositories: {report['total_repos']}")
            print(f"Average Stars: {report['avg_stars']:.1f}")
            print(f"Most Popular Language: {report['top_language']}")
            print("\nSize Distribution:")
            for size, count in report['size_distribution']:
                print(f"  - {size}: {count} repositories")
            
            return "Report generated successfully"
            
    except Error as e:
        print(f"❌ Error generating report: {e}")
        raise
    finally:
        if connection and connection.is_connected():
            cursor.close()
            connection.close()

# Define tasks
extract_task = PythonOperator(
    task_id='extract_github_data',
    python_callable=extract_github_data,
    dag=dag,
)

transform_task = PythonOperator(
    task_id='transform_github_data',
    python_callable=transform_github_data,
    dag=dag,
)

load_task = PythonOperator(
    task_id='load_to_mysql',
    python_callable=load_to_mysql,
    dag=dag,
)

report_task = PythonOperator(
    task_id='generate_report',
    python_callable=generate_report,
    dag=dag,
)

# Health check task
health_check = BashOperator(
    task_id='health_check',
    bash_command='''
    echo "🏥 ETL Health Check"
    echo "DAG: github_mysql_etl_dag"
    echo "Execution Date: {{ ds }}"
    echo "Run ID: {{ dag_run.run_id }}"
    echo "Status: Pipeline completed successfully!"
    ''',
    dag=dag,
)

# Set task dependencies
extract_task >> transform_task >> load_task >> report_task >> health_check
