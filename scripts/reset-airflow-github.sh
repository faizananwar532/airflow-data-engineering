#!/bin/bash

# Script to reset Airflow deployment with clean S3 configuration
set -e

echo "===== Resetting Airflow Deployment ====="

# Step 1: Clean up MySQL database to avoid schema conflicts
echo "Cleaning up MySQL database..."
$(dirname "$0")/clean-mysql-db.sh

# Step 2: Delete the current Airflow namespace
echo "Deleting current Airflow namespace..."
kubectl delete namespace airflow

# Wait for namespace to be fully deleted
echo "Waiting for namespace deletion to complete..."
while kubectl get namespace airflow &>/dev/null; do
    echo "Waiting..."
    sleep 5
done

# Step 3: Create a new Airflow namespace
echo "Creating new Airflow namespace..."
kubectl create namespace airflow

# Step 4: Create S3 buckets if they don't exist
echo "Checking/creating S3 buckets..."
aws s3 ls s3://airflow-dags-ravi || aws s3 mb s3://airflow-dags-ravi
aws s3 ls s3://airflow-logs-ravi || aws s3 mb s3://airflow-logs-ravi

# Step 5: Create MySQL connection secrets
echo "Creating MySQL connection secrets..."
kubectl create secret generic airflow-mysql-metadata \
    --namespace airflow \
    --from-literal=connection="mysql://myuser:mypassword@MYSQL_HOST:3306/mydb"

kubectl create secret generic airflow-mysql-result-backend \
    --namespace airflow \
    --from-literal=connection="db+mysql://myuser:mypassword@MYSQL_HOST:3306/mydb"

# Step 6: Apply the advanced test DAG ConfigMap
echo "Applying advanced test DAG ConfigMap..."
kubectl apply -f /home/faizi/Desktop/hunzala/ravi/airflow-data-engineering/airflow-1.15/airflow-advanced-test-dag-configmap.yaml -n airflow

# Step 7: Install Airflow with Helm using the MySQL values
echo "Installing Airflow with MySQL and S3 configuration..."
helm install air /home/faizi/Desktop/hunzala/ravi/airflow-data-engineering/airflow-1.15 \
    --namespace airflow \
    --values /home/faizi/Desktop/hunzala/ravi/airflow-data-engineering/airflow-1.15/mysql-github-values.yaml

# Step 8: Wait for the webserver pod to be ready
echo "Waiting for Airflow webserver to be ready..."
kubectl wait --for=condition=Ready pod -l component=webserver -n airflow --timeout=300s

# Step 9: Add MySQL connection
echo "Adding MySQL connection to Airflow..."
# Copy the script to the pod
WEBSERVER_POD=$(kubectl get pods -n airflow -l component=webserver -o jsonpath="{.items[0].metadata.name}")
kubectl cp "$(dirname "$0")/add_mysql_connection.py" "airflow/$WEBSERVER_POD:/tmp/add_mysql_connection.py" -c webserver
kubectl exec -n airflow $WEBSERVER_POD -c webserver -- chmod +x /tmp/add_mysql_connection.py
kubectl exec -n airflow $WEBSERVER_POD -c webserver -- python /tmp/add_mysql_connection.py

echo "===== Airflow Reset Complete ====="
echo "It may take a few minutes for all pods to start."
echo "Monitor the status with: kubectl get pods -n airflow -w"
echo ""
echo "After Airflow is running, upload your DAGs to S3 with:"
echo "python airflow-data-engineering/scripts/upload_etl_dag_to_s3.py"
echo ""
echo "The advanced test DAG is automatically deployed and should be available in the Airflow UI." 