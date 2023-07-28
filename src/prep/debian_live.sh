#!/bin/sh

# If you are installing this on VirtualBox to test it out, set RAM bigger than
# 1024MB as otherwise it errors out (running out of cache/RAM space)

#set echo off

main() {
    if [ -z "$HOME" ]; then HOME=~ ; fi
    RELEASE="bookworm"
    prep_packages="btrfs-progs cryptsetup debootstrap dialog dosfstools efibootmgr git ntp parted tmux zip unzip tar"

  # attempt to install and if errors sync time and database
    apt-get -y --fix-broken install $prep_packages
    [ $? != 0 ] && sync_time && echo "Please wait for 30 seconds!" && sleep 30 && fixdb && apt-get -y --fix-broken install $prep_packages

    configs
    #git clone http://github.com/ashos/ashos
    git config --global --add safe.directory $HOME/ashos # prevent fatal error "unsafe repository is owned by someone else"
    #cd ashos
    dialog --stdout --msgbox "CAUTION: If you hit Okay, your HDD will be partitioned. You should confirm you edited script in prep folder!" 0 0
    # Uncomment the line below if you want to prepare/partition the drive automatically - not recommend for a disk with data
    #/bin/bash ./src/prep/parted_gpt_example.sh $2
    # Uncomment the line below if you want this script to also run setup.py, example: setup.py root-partition disk efi-partition
    #python3 setup.py $1 $2 $3
}

# Configurations
configs() {
    # Uncomment the setfont below to use that font
    #setfont Lat38-TerminusBold24x12 # /usr/share/consolefonts/
    echo "export LC_ALL=C LC_CTYPE=C LANGUAGE=C" >> $HOME/.bashrc
    #echo "alias p='curl -F "'"sprunge=<-"'" sprunge.us'" >> $HOME/.bashrc
    echo "alias p='curl -F "'"f:1=<-"'" ix.io'" >> $HOME/.bashrc
    echo "alias d='df -h | grep -v sda'" >> $HOME/.bashrc
    echo "setw -g mode-keys vi" >> $HOME/.tmux.conf
    echo "set -g history-limit 999999" >> $HOME/.tmux.conf
    echo "alias ll='ls -ltrah'" >> $HOME/.bash_aliases
}

# Remove man pages (fixes slow man-db trigger) and update packages db
fixdb() {
    sed -i "s/[^ ]*[^ ]/$RELEASE/3" /etc/apt/sources.list
    apt-get -y autoremove
    apt-get -y autoclean
    apt-get -y clean # Needed?
    apt-get -y remove --purge man-db # Fix slow man-db trigger
    apt-get -y update
    apt-get -y check # Needed?
}

# Sync time
sync_time() {
    if [ -x "$(command -v wget)" ]; then
        date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
    elif [ -x "$(command -v curl)" ]; then
        date -s "$(curl -I google.com 2>&1 | grep Date: | cut -d' ' -f3-6)Z"
    else
        echo "F: Syncing time failed! Neither wget nor curl available."
    fi
}

main "$@"; exit

