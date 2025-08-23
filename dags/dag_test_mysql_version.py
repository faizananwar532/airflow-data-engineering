# This dag test checks the connection to the MySQL database
# and prints a message indicating whether the connection was successful or not.

#!/usr/bin/env python3

import pymysql
import sys

def test_connection():
    try:
        print("Testing connection to MySQL at MYSQL_HOST...")
        conn = pymysql.connect(
            host='MYSQL_HOST',
            user='myuser',
            password='mypassword',
            database='mydb',
            port=3306
        )
        
        print("Connection successful!")
        
        # Test executing a query
        with conn.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"MySQL version: {version[0]}")
            
        conn.close()
        return True
    except Exception as e:
        print(f"Connection failed: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    if not success:
        sys.exit(1) 