#!/bin/bash

unicorn_pid_file=log/unicorn.pid
unicorn_conf=config/unicorn.rb

# Get the pid if we can
if [ -f ${unicorn_pid_file} ]; then
    unicorn_pid=$(cat ${unicorn_pid_file})
fi

start() {
    bundle exec unicorn -c ${unicorn_conf} -D
}

restart() {
    kill -USR2 ${unicorn_pid}
}

stop() {
    kill -TERM ${unicorn_pid}
}

case $1 in
    start) if [ -e ${unicorn_pid} ]; then start; fi ;;
    restart) if [ -e ${unicorn_pid} ]; then start; else restart; fi ;;
    stop) if ! [ -e ${unicorn_pid} ]; then stop; fi ;;
    *) echo "Usage: ${0} start|restart|stop"
esac
