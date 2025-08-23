-- Script to clean up MySQL database for Airflow
-- This will drop all Airflow tables and allow Airflow to recreate them with the correct schema

-- Disable foreign key checks to allow dropping tables with foreign key constraints
SET FOREIGN_KEY_CHECKS = 0;

-- Drop all tables in the database to allow Airflow to recreate them
DROP TABLE IF EXISTS ab_permission;
DROP TABLE IF EXISTS ab_permission_view;
DROP TABLE IF EXISTS ab_permission_view_role;
DROP TABLE IF EXISTS ab_register_user;
DROP TABLE IF EXISTS ab_role;
DROP TABLE IF EXISTS ab_user;
DROP TABLE IF EXISTS ab_user_role;
DROP TABLE IF EXISTS ab_view_menu;
DROP TABLE IF EXISTS alembic_version;
DROP TABLE IF EXISTS callback_request;
DROP TABLE IF EXISTS celery_taskmeta;
DROP TABLE IF EXISTS celery_tasksetmeta;
DROP TABLE IF EXISTS connection;
DROP TABLE IF EXISTS dag;
DROP TABLE IF EXISTS dag_code;
DROP TABLE IF EXISTS dag_pickle;
DROP TABLE IF EXISTS dag_run;
DROP TABLE IF EXISTS dag_tag;
DROP TABLE IF EXISTS dataset;
DROP TABLE IF EXISTS dataset_dag_run_queue;
DROP TABLE IF EXISTS dataset_event;
DROP TABLE IF EXISTS import_error;
DROP TABLE IF EXISTS job;
DROP TABLE IF EXISTS log;
DROP TABLE IF EXISTS log_template;
DROP TABLE IF EXISTS rendered_task_instance_fields;
DROP TABLE IF EXISTS sensor_instance;
DROP TABLE IF EXISTS serialized_dag;
DROP TABLE IF EXISTS session;
DROP TABLE IF EXISTS sla_miss;
DROP TABLE IF EXISTS slot_pool;
DROP TABLE IF EXISTS task_fail;
DROP TABLE IF EXISTS task_instance;
DROP TABLE IF EXISTS task_map;
DROP TABLE IF EXISTS task_outlet_dataset_reference;
DROP TABLE IF EXISTS task_reschedule;
DROP TABLE IF EXISTS `trigger`;
DROP TABLE IF EXISTS variable;
DROP TABLE IF EXISTS xcom;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1; 