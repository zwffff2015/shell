#!/bin/bash

username="hadoop"

userdel $username
rm -rf /home/$username

chown -R root:root expectScriptLogin.sh
rm -rf /usr/local/hadoop/

# delete the last three rows
A=$(sed -n '$=' /etc/hosts)
sed -i $(($A-3+1)),${A}d /etc/hosts
