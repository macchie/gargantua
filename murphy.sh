#!/bin/bash
# <UDF name="notification_email" Label="Email for Confirmation" default="" example="Example: your@email.com" />

# <UDF name="hostname" Label="Hostname" default="" example="Example: koodit_Server" />


# <UDF name="user_username" Label="Server Account Username" default="koodit" example="Example: koodit" />
# <UDF name="user_password" Label="Server Account Password" default="Password123!" example="Example: 987654321!" />
# <UDF name="ssh_port" Label="Server SSH Port" default="6666" example="Example: 1234" />

# System Update
function system_update {
  apt-get update
}

# User Add Sudo
function user_add_sudo {
    USERNAME="$1"
    USERPASS="$2"

    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPASS" ]; then
        echo "No new username and/or password entered"
        return 1;
    fi

    adduser $USERNAME --disabled-password --gecos ""
    echo "$USERNAME:$USERPASS" | chpasswd
    usermod -aG sudo $USERNAME
}

# Disables root SSH access.
function ssh_disable_root {
    sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    touch /tmp/restart-ssh
}

# Installs postfix and configure to listen only on the local interface. Also allows for local mail delivery
function postfix_install_loopback_only {
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mailname string localhost" | debconf-set-selections
    echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
    aptitude -y install postfix
    /usr/sbin/postconf -e "inet_interfaces = loopback-only"
    #/usr/sbin/postconf -e "local_transport = error:local delivery is disabled"

    touch /tmp/restart-postfix
}

# Setup hostname
function system_set_hostname {
    # $1 - The hostname to define
    HOSTNAME="$1"

    if [ ! -n "$HOSTNAME" ]; then
        echo "Hostname undefined"
        return 1;
    fi

    echo "$HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname
}

# Add host entry in /etc/hosts
function system_add_host_entry {
    # $1 - The IP address to set a hosts entry for
    # $2 - The FQDN to set to the IP
    IPADDR="$1"
    FQDN="$2"

    if [ -z "$IPADDR" -o -z "$FQDN" ]; then
        echo "IP address and/or FQDN Undefined"
        return 1;
    fi

    echo $IPADDR $FQDN  >> /etc/hosts
}

# Enables color root prompt and the "ll" list long alias
function goodstuff {
    sed -i -e 's/^#PS1=/PS1=/' /root/.bashrc # enable the colorful root bash prompt
    sed -i -e "s/^#alias ll='ls -l'/alias ll='ls -al'/" /root/.bashrc # enable ll list long alias <3
}

# utility functions

function restart_services {
    # restarts services that have a file in /tmp/needs-restart/
    for service in $(ls /tmp/restart-* | cut -d- -f2-10); do
        /etc/init.d/$service restart
        rm -f /tmp/restart-$service
    done
}

# # common libraries

function setup_dependencies {
  apt-get install -y curl
  apt-get install -y git-core
  apt-get install -y imagemagick
  apt-get install -y libmagickwand-dev
  apt-get install -y nodejs
  apt-get install -y nodejs-legacy
  apt-get install -y default-jre
}

# all went good

function imready {
  # send mail
  curl -A 'Mandrill-Curl/1.0' -X POST -H "Content-Type: application/json" --data '{"key":"8TGbblcuNApLQRAw4FQ4Jw","merge":true, "message":{"text":"Server setup complete, check /SETUP_LOG for details.","subject":"Linode Server Complete","from_email":"new.server@koodit.it","from_name":"Linode Server","to":[{"email":"a.macchieraldo@koodit.it","type":"to"}]}}' 'https://mandrillapp.com/api/1.0/messages/send.json'
}

##### SETUP START

# system update just in case
system_update
cat >> /SETUP_LOG <<EOD
SYSTEM UPDATED
EOD

# setup hostname
system_set_hostname $HOSTNAME
cat >> /SETUP_LOG <<EOD
SYSTEM HOSTNAME IS NOW '$HOSTNAME'
EOD

# setup system hostnames
system_add_host_entry "127.0.0.1" $HOSTNAME
cat >> /SETUP_LOG <<EOD
HOST ENTRY FOR '$HOSTNAME' ADDED TO /etc/hosts
EOD

# add sudo user and disable root access
user_add_sudo "$USER_USERNAME" "$USER_PASSWORD"
cat >> /SETUP_LOG <<EOD
USER '$USER_USERNAME' CREATED WITH PASSWORD '$USER_PASSWORD' AND ADDED TO SUDO
EOD

ssh_disable_root
cat >> /SETUP_LOG <<EOD
SSH ACCESS FOR ROOT DISABLED
EOD

# setup postfix
postfix_install_loopback_only
cat >> /SETUP_LOG <<EOD
POSTFIX SETUP COMPLETE
EOD

# setup webserver with common dependencies & remove default site
setup_dependencies
cat >> /SETUP_LOG <<EOD
# SETUP DEPENCENCIES
  curl INSTALLED
  git-core INSTALLED
  imagemagick INSTALLED
  libmagickwand-dev INSTALLED
  nodejs INSTALLED
# END SETUP WEBSERVER
EOD

# goodies & goodbye
goodstuff
cat >> /SETUP_LOG <<EOD
GOODSTUFF ENABLED
EOD

restart_services
cat >> /SETUP_LOG <<EOD
SERVICES RESTARTED
EOD

cat >> /SETUP_LOG <<EOD

ALL WENT WELL. ENJOY!

PS: DELETE ME

EOD

imready

reboot
