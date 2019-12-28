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
ENV WPCRON_SSH_HANDLE="wpcron@docker-dev.activemode.io" \
    WPCRON_SSH_PRIVKEY="/wp-cron/ssh/id-rsa" \
    WPCRON_DB_PORT="3306" \
    WPCRON_DB_HOST="maria-dev" \
    WPCRON_DB_DATABASE="agility-web" \
    WPCRON_DB_USERNAME="agility-web" \
    WPCRON_DB_PASSWORD="secret" \
    WPCRON_S3_ENDPOINT="http://minio-dev:9000" \
    WPCRON_S3_ACCESS_KEY="21502C4E9A5F5A558F67" \
    WPCRON_S3_SECRET_KEY="gxYcG9zvzN3VH9EgWMBLbKy3ut/9SZVq68hIbZVx"

WORKDIR /wp-cron

COPY ./jobs ./jobs
ADD ./entrypoint.sh ./entrypoint.sh

RUN chmod +x -R \
    ./jobs/helpers \
    ./jobs/scripts \
    ./entrypoint.sh; \
    printenv;

ENTRYPOINT ./entrypoint.sh




