#!/bin/bash

username="hadoop"

userdel $username
rm -rf /home/$username

chown -R root:root expectScriptLogin.sh
rm -rf /usr/local/hadoop/

