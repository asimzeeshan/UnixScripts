#!/bin/bash

# Cleanup messy OS templates
service apache2 stop
service sendmail stop
service bind9 stop
service nscd stop
apt-get purge nscd bind9 sendmail apache2
