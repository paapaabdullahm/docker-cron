#!/usr/bin/env bash

# Start the run once job.
echo "Docker Cron container started"

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /docker-cron/jobs.env

# Configure jobs
crontab /docker-cron/jobs/scheduler.txt

# Run jobs on container startup
cron -f
