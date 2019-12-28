# WP Cron

WP Cron is a set of cron jobs for automating routine SysAdmin tasks for a dockerized micro-service

## Requirements

### Create a user for executing remote jobs

ssh into docker host

```
$ ssh pam79@docker-dev.activemode.io
```

create a new user with password as wpcron and accept the defaults

```
$ sudo adduser wpcron
```

add user to the sudoers group

```
$ usermod -aG sudo wpcron
```

allow user to execute sudo commands without a prompt

```
$ echo "wpcron ALL=(ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers
```
run a smoke test

```
$ su - wpcron
$ sudo ls -la /root
$ exit
$ exit
```

exit the current ssh session

```
$ exit
```

### Let user Connect to the docker host machine via SSH

> NB: Because the ssh keys are very sensitive security credentials, they will be separately created for each environment that the image is deployed and bind mounted into the container during execution.
>
> For dev environments, add the credentials folder directly to your project at ./etc/ssh directory. Make sure ./etc/ssh/ is ignored by git
>
> For stage and production, credentials are created and stored in jenkins and copied over to the docker host at deployment time.

add credentials folder to hold generated keys

```
$ sudo mkdir -p ./etc/ssh
```

generate keys

```
$ sudo ssh-keygen -t rsa -f ./etc/ssh/id-rsa -C wpcron
```

add public ssh key to the docker host

```
$ cat ./etc/ssh/id-rsa.pub
$ ssh pam79@docker-dev.activemode.io
$ sudo mkdir -p /home/wpcron/.ssh
$ sudo vim /home/wpcron/.ssh/authorized_keys
```

paste the cat public keys into the authorized_keys file

```
$ Ctrl + Shift + V
```

secure authorized_keys file

```
$ sudo chown -R wpcron:wpcron /home/wpcron/.ssh
$ sudo chmod 700 /home/wpcron/.ssh
$ sudo chmod 600 /home/wpcron/.ssh/authorized_keys
```

exit docker host

```
$ exit
```

create a volume for your wp-cron service

```
volumes:
ssh-keys: # credentials volume
  driver: local
  driver_opts:
    o: bind
    type: none
    device: ${PWD}/etc/ssh
```

bind mount the volume inside the wp-cron service

```
volume:
  type: bind
  source: ssh-keys
  target: /wp-cron/ssh
```

let your wp-cron container use this to run jobs

```
ssh -i /wpcron/ssh/id-rsa -o StrictHostKeyChecking=accept-new wpcron@docker-dev.activemode.io
```
