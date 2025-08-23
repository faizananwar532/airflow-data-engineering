# Direct GitHub to Airflow Sync

This setup allows your Airflow deployment to automatically sync DAGs directly from your GitHub repository without using S3 or GitHub Actions.

## How it Works

1. **Git Sidecar Containers**: Each Airflow component (scheduler, webserver, workers) has a Git sidecar container
2. **Automatic Cloning**: The sidecar containers clone your GitHub repository every 60 seconds (configurable)
3. **DAG Sync**: Python files from the `dags/` directory are automatically copied to Airflow
4. **No External Dependencies**: No need for S3, GitHub Actions, or webhooks

## Quick Setup

1. **Run the setup script**:
   ```bash
   cd scripts
   ./setup-direct-github-sync.sh
   ```

2. **Follow the prompts** to enter your GitHub repository details

3. **Push to GitHub**:
   ```bash
   git push -u origin main
   ```

4. **Deploy Airflow** with the new configuration

## Architecture

```
GitHub Repository
       ↓
   Git Sidecar Container (alpine/git)
       ↓
   /opt/airflow/dags (emptyDir volume)
       ↓
   Airflow Scheduler/Webserver/Workers
```

## Configuration

The sync behavior is controlled by environment variables in `mysql-github-values.yaml`:

- `GIT_REPO_URL`: Your GitHub repository URL
- `GIT_BRANCH`: Branch to sync from (default: main)
- `GIT_SYNC_INTERVAL`: Sync interval in seconds (default: 60)

## Repository Structure

Your GitHub repository should have this structure:
```
your-repo/
├── dags/
│   ├── dag_example1.py
│   ├── dag_example2.py
│   └── ...
├── scripts/
├── README.md
└── other files...
```

Only files in the `dags/` directory will be synced to Airflow.

## Benefits

- ✅ **Simple**: No complex CI/CD pipelines needed
- ✅ **Fast**: Direct sync every 60 seconds
- ✅ **Reliable**: Uses standard Git operations
- ✅ **No External Services**: No dependency on S3 or GitHub Actions
- ✅ **Real-time**: Changes appear quickly in Airflow

## Testing

1. Create a new DAG file in the `dags/` directory
2. Commit and push to GitHub
3. Wait up to 60 seconds
4. Check the Airflow UI - your new DAG should appear

## Troubleshooting

### DAGs not appearing
- Check Git sidecar logs: `kubectl logs -n airflow POD_NAME -c dags-git-sync`
- Verify repository URL and branch name
- Ensure `dags/` directory exists in your repository

### Git sync errors
- For private repositories, you'll need to configure Git credentials
- Check network connectivity from your Kubernetes cluster to GitHub

### Performance
- Adjust `GIT_SYNC_INTERVAL` based on your needs
- Consider using shallow clones (already configured with `--depth 1`)

## Private Repositories

For private repositories, you'll need to add Git credentials. This can be done by:
1. Creating a GitHub personal access token
2. Adding it as a Kubernetes secret
3. Mounting the secret in the Git sidecar containers

## Monitoring

Monitor the sync process by checking the Git sidecar container logs:
```bash
kubectl logs -n airflow -l component=scheduler -c dags-git-sync --follow
```

You should see regular sync messages every 60 seconds.

## Customization

You can customize the sync behavior by modifying the Git sidecar configuration in `mysql-github-values.yaml`:
- Change the sync interval
- Add authentication for private repos
- Modify the clone depth
- Add file filtering logic
