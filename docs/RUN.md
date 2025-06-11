# Running Guide
Once the environment is installed and the Docker services are started, follow this guide to access and manage your application.

## Start Docker Compose
This runs docker-compose in the `docker/` directory and starts all services in the background
```bash
$ make start
```
After the Docker services have started successfully, access the application at: https://&lt;your-configured-domain-or-IP&gt;

## Make Options
### Check Logs
```bash
$ make logs
```

### Stop Docker Compose
```bash
$ make stop
```

### Cleanup
```bash
make clean-docker   # Stop & remove containers/volumes
make clean-env      # Remove generated .env and cert files
make clean-data     # Clear application and remove stored data
```
