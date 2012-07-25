#!/bin/bash

# Cleanup messy OS templates
service apache2 stop
service sendmail stop
service bind9 stop
service nscd stop
service samba stop
noninteractive apt-get -q -y remove --purge nscd bind9 'apache2*' 'samba*' 'sendmail*'
