#!/usr/bin/env bash

# Start the run once job.
echo "WP Cron container started"

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /wp-cron/jobs.env

# Configure jobs
crontab /wp-cron/jobs/scheduler.txt

# Run jobs on container startup
cron -f
