#!/usr/bin/env python3
"""
Script to add MySQL connection to Airflow
"""
import sys
import os
import subprocess
import time

# Run this script in a pod with airflow CLI available
def main():
    print("Adding MySQL connection to Airflow...")
    
    # Define the connection parameters
    conn_id = "mysql"
    conn_uri = "mysql://myuser:mypassword@MYSQL_HOST:3306/mydb"
    
    # Command to add the connection
    cmd = f"airflow connections add {conn_id} --conn-uri '{conn_uri}'"
    
    print(f"Running command: {cmd}")
    
    # Execute the command
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        print("MySQL connection added successfully!")
        print(result.stdout)
    else:
        print("Failed to add MySQL connection:")
        print(result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main() 