# Docker Cron

Docker Cron is a dockerized service with a set of cron jobs for automating routine SysAdmin tasks for a dockerized application. The cron jobs can easily be customized or completely overridden by bind mounting your own scripts.


Some use cases currently implemented:
- Update and upgrade packages on the docker host where your application is running.

Other use cases soon to be implemented:
- Cleanup after docker leftovers.
- Backup application data to object store.
- Backup databases to object store.
- Renewal of let'sencrypt certificates.

## Environment Variables

The running container accepts the following environmental variables for establishing ssh connections, connecting to databases and s3 compatible object storage endpoints to execute backup and other admin related jobs:

<table width="100%">
    <tr>
        <th>Env Variable</th>
        <th>Description</th>
        <th>Example</th>
    </tr>
    <tr>
        <td>DOCKER_CRON_SSH_HANDLE</td>
        <td>The SSH connection handle</td>
        <td>docker-cron@example.com</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_SSH_PRIVKEY</td>
        <td>your private identity file</td>
        <td>/docker-cron/ssh/id-rsa</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_DB_PORT</td>
        <td>Database Port</td>
        <td>3306</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_DB_HOST</td>
        <td>Database Host</td>
        <td>mariadb.example.com</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_DB_DATABASE</td>
        <td>Database Name</td>
        <td>example-db-name</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_DB_USERNAME</td>
        <td>Database User</td>
        <td>example-db-user</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_DB_PASSWORD</td>
        <td>Database Password</td>
        <td>example-db-secret</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_S3_ENDPOINT</td>
        <td>S3 object store endpoint</td>
        <td>http://example-endpoint:9000</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_S3_ACCESS_KEY</td>
        <td>S3 object store access key</td>
        <td>21502C4E9A5F5A558F67</td>
    </tr>
    <tr>
        <td>DOCKER_CRON_S3_SECRET_KEY</td>
        <td>S3 object store secret key</td>
        <td>gxYcG9zvzN3VH9EgW-MBLbKy3ut/9S-ZVq68hIbZVx</td>
    </tr>
</table>

## How to set it up

### Create a user for executing remote jobs
> Here, remote can be the same host on which you are running your docker-cron service, any other stand-alone servers or servers that are part of a kubernetes/swarm cluster.

SSH into your docker host or any remote that docker-cron will administer

```
$ ssh pam79@docker-dev.example.com
```

Create a new user with password as docker-cron or something else and accept the defaults

```
$ sudo adduser docker-cron
```

Add the docker-cron user to the sudoers group

```
$ sudo usermod -aG sudo docker-cron
```

Allow the docker-cron user to execute sudo commands without any prompt

```
$ echo "docker-cron ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers
```

Run a smoke test

```
$ su - docker-cron
$ sudo ls -la /root
$ exit
$ exit
```

Exit the current ssh session

```
$ exit
```

### Allow docker-cron user, access to the remote host via SSH

> NB: Because the ssh keys are very sensitive security credentials, they should be created separately for each environment the service is deployed and bind mounted into the container during execution via docker volumes.
>
> For dev environments, add the credentials folder directly within your project root at `./etc/ssh/`. Make sure the `./etc/ssh/` directory is ignored by git.
>
> For stage and production, SSH credentials should be generated and stored with CI and secret management tools, and copied over to the remote host at deployment time.

Create folder to hold generated ssh keys in your project root

```
$ sudo mkdir -p ./etc/ssh
```

Generate ssh keys

```
$ sudo ssh-keygen -t rsa -f ./etc/ssh/id-rsa -C docker-cron
```

Add public ssh key to the docker/remote host

```
$ cat ./etc/ssh/id-rsa.pub
$ ssh pam79@docker-dev.example.com
$ sudo mkdir -p /home/docker-cron/.ssh
$ sudo vim /home/docker-cron/.ssh/authorized_keys
```

Copy and paste the public keys you displayed using the `cat` command, into the authorized_keys file

```
$ Ctrl + Shift + V
```

Secure authorized_keys file on the remote host

```
$ sudo chown -R docker-cron:docker-cron /home/docker-cron/.ssh
$ sudo chmod 700 /home/docker-cron/.ssh
$ sudo chmod 600 /home/docker-cron/.ssh/authorized_keys
```

Finally, disable ssh root access and ssh password authentication
> It is very important that you execute this final step to
> prevent your server from getting hacked via brute-force attack.

```
$ sudo sed -i '/^#PasswordAuthentication[ \t]\+\w\+$/{ \
  s//PasswordAuthentication no/g; \
  }' /etc/ssh/sshd_config
```

Exit the remote ssh session

```
$ exit
```

Create a volume for your docker-cron service

```
volumes:
  ssh-keys: # credentials volume
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${APP_PWD}/etc/ssh
```

And mount the volume inside the docker-cron service

```
volume:
  type: volume
  source: ssh-keys
  target: /docker-cron/ssh
```

Here is an example SSH connection that can be established by your docker-cron container to run admin jobs remotely or on the same docker host.

```
ssh -i /docker-cron/ssh/id-rsa \
    -o StrictHostKeyChecking=accept-new \
    docker-cron@docker-dev.example.com
```

## Docker Compose Example

```
version: '3.7'

services:

  nginx: # web server
    image: pam79/nginx
    container_name: nginx
    volumes:
      - type: volume
        source: src-code
        target: /usr/share/nginx/html
      - type: bind
        source: ./default.conf
        target: /etc/nginx/conf.d/default.conf
    tty: true
    stdin_open: true
    depends_on:
      php:
    networks:
      - proxy-tier
      - app-tier
    restart: on-failure

  php: # web app
    image: pam79/php-fpm:v7.4.1
    container_name: php
    volumes:
      - type: volume
        source: src-code
        target: /usr/share/nginx/html
      - type: bind
        source: ./custom.ini
        target: /usr/local/etc/php/conf.d/custom.ini
    networks:
      - app-tier
      - cron-tier
    restart: on-failure

  docker-cron: # service for running admin jobs
    image: pam79/docker-cron:v1.0.0
    container_name: docker-cron
    volumes:
      - type: volume
        source: src-code
        target: /usr/share/nginx/html
      - type: volume
        source: cron-logs
        target: /var/log/cron
    environment:
      - DOCKER_CRON_SSH_HANDLE="docker-cron@example.com"
      - DOCKER_CRON_SSH_PRIVKEY="/docker-cron/ssh/id-rsa"
      - DOCKER_CRON_DB_PORT="3306"
      - DOCKER_CRON_DB_HOST="mariadb.example.com"
      - DOCKER_CRON_DB_DATABASE="example-db-name"
      - DOCKER_CRON_DB_USERNAME="example-db-use"
      - DOCKER_CRON_DB_PASSWORD="example-db-secret"
      - DOCKER_CRON_S3_ENDPOINT="http://example-endpoint:9000"
      - DOCKER_CRON_S3_ACCESS_KEY="21502C4E9A5F5A558F67"
      - DOCKER_CRON_S3_SECRET_KEY="gxYcG9zvzN3VH9EgW-MBLbKy3ut/9S-ZVq68hIbZVx"
    networks:
      - cron-tier
    restart: on-failure

volumes:

  src-code:
    driver_opts:
      o: bind
      type: none
      device: ${APP_PWD}

  cron-logs:
    driver: local

  ssh-keys:
    driver_opts:
      o: bind
      type: none
      device: ${APP_PWD}/etc/ssh

networks:

  proxy-tier:
    driver: bridge

  app-tier:
      driver: bridge

  cron-tier:
      driver: bridge
```
