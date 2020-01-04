#!/usr/bin/env bash

#Filename: apt.sh
#Description: Automate update of the docker/remote host's operating system

SSH_HANDLE=${DOCKER_CRON_SSH_HANDLE}
SSH_PRIVKEY=${DOCKER_CRON_SSH_PRIVKEY}
SSH_CHALLENGE="StrictHostKeyChecking=accept-new"
VAR1=''
VAR2=''

ssh -i ${SSH_PRIVKEY} -o ${SSH_CHALLENGE} ${SSH_HANDLE} \
var1=${VAR1} var2=${VAR2} 'bash -s' < /docker-cron/jobs/helpers/apt_update_helper
