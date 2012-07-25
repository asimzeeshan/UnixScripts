#!/bin/bash
###############################################################################################
# Complete LAMP setup script for Debian using mod_fcgid and apache2_suexec                    #
# LAMP stack is tuned for a 256MB VPS                                                         #
# Email your questions to s@tuxlite.com                                                       #
###############################################################################################

source ./options.conf

###Functions Begin###

function basic_server_setup {

#Reconfigure sshd - change port and disable root login
sed -i 's/^Port [0-9]*/Port '${SSHD_PORT}'/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
/etc/init.d/ssh reload

#Set hostname and FQDN
sed -i 's/'${SERVER_IP}'.*/'${SERVER_IP}' '${HOSTNAME_FQDN}' '${HOSTNAME}'/' /etc/hosts
echo "$HOSTNAME" > /etc/hostname
/etc/init.d/hostname.sh start

#Basic hardening of sysctl.conf
sed -i 's/^#net.ipv4.conf.all.accept_source_route = 0/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
sed -i 's/^net.ipv4.conf.all.accept_source_route = 1/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
sed -i 's/^#net.ipv6.conf.all.accept_source_route = 0/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf
sed -i 's/^net.ipv6.conf.all.accept_source_route = 1/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf

#Updates server and install commonly used utilities
aptitude update
aptitude -y safe-upgrade
aptitude install nano fail2ban screen
#aptitude -y install vim htop lynx dnsutils unzip byobu

} #end function basic_server_setup


function setup_apt {

#No longer necessary to use the line below for Debian 6 it seems...
#echo 'APT::Default-Release "stable";' >>/etc/apt/apt.conf

#Add Unstable, Testing repositories and configure pin priority to favor Stable packages
#Mainly to allow installation of php5-fpm package that is not in Stable repo

cp /etc/apt/{sources.list,sources.list.bak}
cat > /etc/apt/sources.list <<EOF
#Stable
deb http://mirrors.buyvm.net/debian/ squeeze main contrib non-free
deb-src http://mirrors.buyvm.net/debian/ squeeze main contrib non-free

#updates
deb http://mirrors.buyvm.net/debian/ squeeze-updates main contrib non-free
deb-src http://mirrors.buyvm.net/debian/ squeeze-updates main contrib non-free

#security
deb http://security.debian.org/ squeeze/updates main contrib non-free
deb-src http://security.debian.org/ squeeze/updates main contrib non-free
EOF

cat > /etc/apt/preferences <<EOF
Package: *
Pin: release a=$RELEASE
Pin-Priority: 700

Package: *
Pin: release a=testing
Pin-Priority: 650

Package: *
Pin: release a=unstable
Pin-Priority: 600
EOF

aptitude update

} #end function setup_apt

function install_rtorrent {

aptitude -y install rtorrent

cp /usr/share/doc/rtorrent/examples/rtorrent.rc /home/$torrentuser/.rtorrent.rc
mkdir /home/$torrentuser/watch
chown $torrentuser:$torrentuser /home/$torrentuser/.rtorrent.rc
chown $torrentuser:$torrentuser /home/$torrentuser/watch

sed -i 's/\#max_peers =.*/max_peers = 100/' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#max_uploads =.*/max_uploads = 25/' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#download_rate =.*/download_rate = 2000/' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#upload_rate =.*/upload_rate = 1000/' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#schedule = watch_directory,5,5,load_start=\.\/watch\/\*\.torrent/schedule = watch_directory,5,5,load_start=.\/watch\/\*.torrent/' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#schedule = untied_directory,5,5,stop_untied=/schedule = untied_directory,5,5,stop_untied=/' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#schedule = low_diskspace,5,60,close_low_diskspace=100M/schedule = low_diskspace,5,60,close_low_diskspace=100M/' /home/$torrentuser/.rtorrent.rc
sed -i '/\#schedule = ratio/ a\ratio.enable=1\nratio.min.set=200;\nratio.max.set=500;\nratio.upload.set=200M; ' /home/$torrentuser/.rtorrent.rc
sed -i 's/\#port_range =.*/port_range = 40000-45000/' /home/$torrentuser/.rtorrent.rc


} #end function install_rtorrent


####Main program begins####
#Show Menu#
if [ ! -n "$1" ]; then
    echo ""
    echo -e  "\033[35;1mIMPORTANT!! Edit Options.conf before executing\033[0m"
    echo -e  "\033[35;1mA standard install would be - basic + apt + rtorrent\033[0m"
    echo ""
    echo -e  "\033[35;1mSelect from the options below to use this script:- \033[0m"
    echo -n  "$0"
    echo -ne "\033[36m basic\033[0m"
    echo     " - Disable root SSH logins, change SSH port and set hostname."

    echo -n "$0"
    echo -ne "\033[36m apt\033[0m"
    echo     " - Reconfigure APT /etc/apt/sources.list to add Unstable repo."

    echo -n "$0"
    echo -ne "\033[36m rtorrent USERNAME\033[0m"
    echo     " - Installs and configures rtorrent to USERNAME's home directory. Watch directory is also added for automated torrent downloads."

    echo ""
    exit
fi
#End Show Menu#



#Start execute functions#
case $1 in
apt)
    setup_apt
    aptitude update
    echo -e "\033[35;1m Unstable and Testing repo added to /etc/apt/sources.list\033[0m"
  ;;
basic)
    basic_server_setup
    echo -e "\033[35;1m Root login disabled, SSH port set to $SSHD_PORT. Hostname set to $HOSTNAME and FQDN to $HOSTNAME_FQDN. \033[0m"
    echo -e "\033[35;1m Remember to create a normal user account for login or you will be locked out from your box! \033[0m"
  ;;
rtorrent)
    if [ $# -eq 2 ]; then
        torrentuser=$2
    else
        echo -e "\033[35;1m Please enter a username! \033[0m"
        exit 0;
    fi

    if [ -d "/home/$torrentuser" ];then
        install_rtorrent
        echo -e "\033[35;1m rtorrent installed! Enjoy! \033[0m"
        echo -e "\033[35;1m A 'watch' folder has been created in the user's home directory. Torrent files in there will start downloading automatically. \033[0m"
        echo -e "\033[35;1m Client configured to seed to a ratio of 2.0. Settings stored in /home/$2/.rtorrent.rc \033[0m"
    else
        echo -e "\033[35;1m User doesn't exist! \033[0m"
    fi
  ;;
esac
#End execute functions#