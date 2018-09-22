#!/bin/sh

doKill() {
	killall -9 lcd4linux
}

configfile() {
	read layout < /tmp/lcd/layout
	test $layout = user && CONF_DIR=/var/etc || CONF_DIR=/etc

	chmod 600 ${CONF_DIR}/lcd4linux.conf
	chown 0:0 ${CONF_DIR}/lcd4linux.conf

	printf "${CONF_DIR}/lcd4linux.conf"
}

doStart() {
	( # do always run in background
		while [ ! -e /tmp/.lcd4linux ]; do sleep 2; done
		/usr/bin/lcd4linux -f $(configfile)
	) &
}

doStop() {
	if [ -e /tmp/lcd4linux.pid ]; then
		# read pid from pidfile
		read PID < /tmp/lcd4linux.pid

		# kill child processes
		CHILDS=$(ps -o pid --ppid $PID --no-heading)
		for CHILD in $CHILDS; do
			kill -KILL $CHILD
		done
		sleep 5

		# terminate main process
		kill -TERM $PID > /dev/null 2>&1 &
		sleep 5
		rm -rf /tmp/lcd
	fi
	if pgrep -x "lcd4linux" > /dev/null 2>&1 &
	then
		doKill
	fi
}

doOff() {
	echo "LCD::backlight(0)" | /usr/bin/lcd4linux -q -i > /dev/null 2>&1
}

case "$1" in
	start)
		doStart
	;;
	stop)
		doOff
		doStop
	;;
	restart)
		doOff
		doStop
		doStart
	;;
	*)
		echo "[${0##*/}] Usage: $0 {start|stop|restart}"
		exit
	;;
esac