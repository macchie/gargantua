# gargantua
Linode Stackscript for Massive Server Setup

## Contents

- Initial System Update
- Hostname Setup
- Add Host Record to /etc/hosts
- Add Sudo User with custom username/password
- Disable SSH access for root user
- Postfix install for emails
- Install common dependencies (curl,libpq-dev,git-core,imagemagick,libmagickwand-dev,nodejs,default-jre)
- Install postgresql (postgresql,postgresql-contrib)
- Configure postgresql for local peers
- Install nginx + phusion passenger for rails applications
- Setup nginx (enable passenger)
- Remove default site from nginx
- Install RVM + requirements
- Install Elasticsearch
- Configure Elasticsearch
- Enable GoodStuffs (terminal colors, ll command)
- Restart interested services
- Sends welcome email
- Reboot System

## Usage

Copy **gargantua.sh** to a new linode stackscript.

### Enjoy! :)