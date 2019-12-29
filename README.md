# WP Cron

WP Cron is a dockerized service with a set of cron jobs for automating routine SysAdmin tasks for a dockerized application. The cron jobs can easily be customized or completely overridden by bind mounting your own scripts.


Some use cases currently implemented:
- Update and upgrade packages on the docker host where your application is running.

Some use cases soon to be implemented:
- Cleanup after docker leftovers.
- Backup application data to object store.
- Backup databases to object store.
- Renewal of let'sencrypt certificates.

## Environment Variables

The running container accepts the following environmental variables for establishing ssh connections, connecting to databases and s3 compatible object storage endpoints to execute backup and other admin related jobs:

<table width="100%">
    <tr>
        <th width="33%">Variable</th>
        <th width="34%">Description</th>
        <th width="33%">Example</th>
    </tr>
    <tr>
        <td width="33%">WPCRON_SSH_HANDLE</td>
        <td width="34%">The SSH connection handle</td>
        <td width="33%">wpcron@example.com</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_SSH_PRIVKEY</td>
        <td width="34%">your private identity file</td>
        <td width="33%">/wp-cron/ssh/id-rsa</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_DB_PORT</td>
        <td width="34%">Database Port</td>
        <td width="33%">3306</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_DB_HOST</td>
        <td width="34%">Database Host</td>
        <td width="33%">mariadb.example.com</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_DB_DATABASE</td>
        <td width="34%">Database Name</td>
        <td width="33%">example-db-name</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_DB_USERNAME</td>
        <td width="34%">Database User</td>
        <td width="33%">example-db-user</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_DB_PASSWORD</td>
        <td width="34%">Database Password</td>
        <td width="33%">example-db-secret</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_S3_ENDPOINT</td>
        <td width="34%">S3 object store endpoint</td>
        <td width="33%">http://example-endpoint:9000</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_S3_ACCESS_KEY</td>
        <td width="34%">S3 object store access key</td>
        <td width="33%">21502C4E9A5F5A558F67</td>
    </tr>
    <tr>
        <td width="33%">WPCRON_S3_SECRET_KEY</td>
        <td width="34%">S3 object store secret key</td>
        <td width="33%">gxYcG9zvzN3VH9EgW-MBLbKy3ut/9S-ZVq68hIbZVx</td>
    </tr>
</table>

## How to set it up

### Create a user for executing remote jobs
> Here, remote can be the same host on which you are running your wp-cron service, any other stand-alone servers or servers that are part of a kubernetes/swarm cluster.

SSH into your docker host or any remote that wp-cron will administer

```
$ ssh admin@docker-dev.example.com
```

Create a new user with password as wpcron or something else and accept the defaults

```
$ sudo adduser wpcron
```

Add the wpcron user to the sudoers group

```
$ sudo usermod -aG sudo wpcron
```

Allow the wpcron user to execute sudo commands without any prompt

```
$ echo "wpcron ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers
```

Run a smoke test

```
$ su - wpcron
$ sudo ls -la /root
$ exit
$ exit
```

Exit the current ssh session

```
$ exit
```

### Allow wpcron user, access to the remote host via SSH

> NB: Because the ssh keys are very sensitive security credentials, they should be created separately for each environment the service is deployed and bind mounted into the container during execution via docker volumes.
>
> For dev environments, add the credentials folder directly within your project root at `./etc/ssh/`. Make sure the `./etc/ssh/` directory is ignored by git.
>
> For stage and production, SHS credentials should be generated and stored with CI and secret management tool, and copied over to the docker/remote host at deployment time.

Create folder to hold generated ssh keys in your project root

```
$ sudo mkdir -p ./etc/ssh
```

Generate ssh keys

```
$ sudo ssh-keygen -t rsa -f ./etc/ssh/id-rsa -C wpcron
```

Add public ssh key to the docker/remote host

```
$ cat ./etc/ssh/id-rsa.pub
$ ssh admin@docker-dev.example.com
$ sudo mkdir -p /home/wpcron/.ssh
$ sudo vim /home/wpcron/.ssh/authorized_keys
```

Copy and paste the public keys you displayed using the `cat` command, into the authorized_keys file

```
$ Ctrl + Shift + V
```

Finally secure authorized_keys file on the remote host

```
$ sudo chown -R wpcron:wpcron /home/wpcron/.ssh
$ sudo chmod 700 /home/wpcron/.ssh
$ sudo chmod 600 /home/wpcron/.ssh/authorized_keys
```

Exit the ssh session on the remote host

```
$ exit
```

Create a volume for your wp-cron service

```
volumes:
  ssh-keys: # credentials volume
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${PWD}/etc/ssh
```

And mount the volume inside the wp-cron service

```
volume:
  type: volume
  source: ssh-keys
  target: /wp-cron/ssh
```

Here is an example SSH connection that can be established by your wp-cron container to run admin jobs remotely or on the same docker host.

```
ssh -i /wpcron/ssh/id-rsa \
    -o StrictHostKeyChecking=accept-new \
    wpcron@docker-dev.example.com
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
      - admin-tier
    restart: on-failure

  wp-cron: # service for running admin jobs
    image: pam79/wp-cron:v1.0.0
    container_name: wp-cron
    volumes:
      - type: volume
        source: src-code
        target: /usr/share/nginx/html
      - type: volume
        source: cron-logs
        target: /var/log/cron
    environment:
      - WPCRON_SSH_HANDLE="wpcron@example.com"
      - WPCRON_SSH_PRIVKEY="/wp-cron/ssh/id-rsa"
      - WPCRON_DB_PORT="3306"
      - WPCRON_DB_HOST="mariadb.example.com"
      - WPCRON_DB_DATABASE="example-db-name"
      - WPCRON_DB_USERNAME="example-db-use"
      - WPCRON_DB_PASSWORD="example-db-secret"
      - WPCRON_S3_ENDPOINT="http://example-endpoint:9000"
      - WPCRON_S3_ACCESS_KEY="21502C4E9A5F5A558F67"
      - WPCRON_S3_SECRET_KEY="gxYcG9zvzN3VH9EgW-MBLbKy3ut/9S-ZVq68hIbZVx"
    networks:
      - admin-tier
    restart: on-failure

volumes:

  src-code:
    driver_opts:
      o: bind
      type: none
      device: ${PWD}

  cron-logs:
    driver: local

  ssh-keys:
    driver_opts:
      o: bind
      type: none
      device: ${PWD}/etc/ssh

networks:

  proxy-tier:
    driver: bridge

  app-tier:
      driver: bridge

  admin-tier:
      driver: bridge
```
