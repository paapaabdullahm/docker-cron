FROM ubuntu:18.04
LABEL maintainer="Paapa Abdullah Morgan <paapaabdullahm@gmail.com>"

# Install dependencies
RUN apt update && apt upgrade && apt install -y \
    openssh-server \
    openssl \
    cron \
    vim \
    jq;

# Setup environment variables to be used by containers
ENV DOCKER_CRON_SSH_HANDLE="" \
    DOCKER_CRON_SSH_PRIVKEY="" \
    DOCKER_CRON_DB_PORT="" \
    DOCKER_CRON_DB_HOST="" \
    DOCKER_CRON_DB_DATABASE="" \
    DOCKER_CRON_DB_USERNAME="" \
    DOCKER_CRON_DB_PASSWORD="" \
    DOCKER_CRON_S3_ENDPOINT="" \
    DOCKER_CRON_S3_ACCESS_KEY="" \
    DOCKER_CRON_S3_SECRET_KEY=""

WORKDIR /docker-cron

COPY ./jobs ./jobs
ADD ./entrypoint.sh ./entrypoint.sh

RUN chmod +x -R \
    ./jobs/helpers \
    ./jobs/scripts \
    ./entrypoint.sh; \
    #
    # Make ssh directory
    mkdir -p ./ssh; \
    #
    # Smoke Test
    ssh -V; \
    printenv;

ENTRYPOINT ./entrypoint.sh
