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
ENV WPCRON_SSH_HANDLE="" \
    WPCRON_SSH_PRIVKEY="" \
    WPCRON_DB_PORT="" \
    WPCRON_DB_HOST="" \
    WPCRON_DB_DATABASE="" \
    WPCRON_DB_USERNAME="" \
    WPCRON_DB_PASSWORD="" \
    WPCRON_S3_ENDPOINT="" \
    WPCRON_S3_ACCESS_KEY="" \
    WPCRON_S3_SECRET_KEY=""

WORKDIR /wp-cron

COPY ./jobs ./jobs
ADD ./entrypoint.sh ./entrypoint.sh

RUN chmod +x -R \
    ./jobs/helpers \
    ./jobs/scripts \
    ./entrypoint.sh; \
    #
    # Smoke Test
    printenv; \
    ssh -V; \
    openssl version; \
    which cron; \
    vim --version | grep VIM; \
    jq;

ENTRYPOINT ./entrypoint.sh
