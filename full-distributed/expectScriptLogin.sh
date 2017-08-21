#!/usr/bin/expect

set host [lindex $argv 0]
set password [lindex $argv 1]
set timeout 30
spawn ssh $host
expect "yes/no)?"
send "yes\r"
expect "password:"
send "$password\r"
