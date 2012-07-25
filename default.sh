#!/bin/bash

# Refresh
apt-get update
apt-get upgrade

# Install my default thingies
apt-get -y install nano fail2ban screen wget aptitude git

# Cleanup messy OS templates
service apache2 stop
service sendmail stop
service bind9 stop
service nscd stop
apt-get purge nscd bind9 sendmail apache2
