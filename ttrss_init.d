#! /bin/sh
### BEGIN INIT INFO
# Provides:          ttrss
# Required-Start:    $local_fs $remote_fs $networking postgresql
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Tiny Tiny RSS update daemon for DOMAIN
# Description:       Update the Tiny Tiny RSS subscribed syndication feeds.
### END INIT INFO

# Author: Pierre-Yves Landuré <pierre-yves@landure.org>
# Edits: Stanislav Sta2s

# Do NOT "set -e"

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Tiny Tiny RSS update daemon"
NAME=$(command basename "${0}")
DISABLED=0
FORKING=1

# Read configuration variable file if it is present
[ -r "/etc/default/${NAME}" ] && . "/etc/default/${NAME}"

DAEMON_SCRIPT="update.php --daemon"

if [ "$FORKING" != "0" ]; then
   DAEMON_SCRIPT="update_daemon2.php"
fi

USER="www-data"
DAEMON=/usr/bin/php
DAEMON_ARGS="${TTRSS_PATH}/${DAEMON_SCRIPT}"
DAEMON_DIR="${TTRSS_PATH}"
PIDFILE="/var/run/${NAME}.pid"
SCRIPTNAME="/etc/init.d/${NAME}"
LOG="/var/log/ttrss.log"

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

if [ "$DISABLED" != "0" -a "$1" != "stop" ]; then
   log_warning_msg "Not starting $DESC - edit /etc/default/tt-rss-DOMAIN and change DISABLED to be 0.";
   exit 0;
fi

#
# Function that starts the daemon/service
#
do_start()
{
   if [ ! -f "$LOG" ]; then
  	touch "$LOG"
	chown "$USER" "$LOG"
   fi

   # Return
   #   0 if daemon has been started
   #   1 if daemon was already running
   #   2 if daemon could not be started
   start-stop-daemon --start --make-pidfile --background --quiet --chuid "$USER" --chdir "$DAEMON_DIR" --pidfile "$PIDFILE" --exec "$DAEMON" --test > /dev/null \
      || return 1

   start-stop-daemon --start --make-pidfile --background --quiet --chuid "$USER" --chdir "$DAEMON_DIR" --pidfile "$PIDFILE" --exec "$DAEMON" -- \
      $DAEMON_ARGS --log $LOG \
      || return 2
   # Add code here, if necessary, that waits for the process to be ready
   # to handle requests from services started subsequently which depend
   # on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
   # Return
   #   0 if daemon has been stopped
   #   1 if daemon was already stopped
   #   2 if daemon could not be stopped
   #   other if a failure occurred
   start-stop-daemon --stop --make-pidfile --quiet --chuid "$USER" --retry=TERM/1/KILL/5 --pidfile $PIDFILE --name $NAME
   RETVAL="$?"
   [ "$RETVAL" = 2 ] && return 2
   # Wait for children to finish too if this is a daemon that forks
   # and if the daemon is only ever run from this initscript.
   # If the above conditions are not satisfied then add some other code
   # that waits for the process to drop all resources that could be
   # needed by services started subsequently.  A last resort is to
   # sleep for some time.
   start-stop-daemon --stop --quiet --oknodo --retry=0/1/KILL/5 --exec $DAEMON
   [ "$?" = 2 ] && return 2
   # Many daemons don't delete their pidfiles when they exit.
   rm -f $PIDFILE
   return "$RETVAL"
}

case "$1" in
  start)
   log_daemon_msg "Starting $DESC" "$NAME"
   do_start
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  stop)
   log_daemon_msg "Stopping $DESC" "$NAME"
   do_stop
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  status)
   status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
   ;;
  restart|force-reload)
   #
   # If the "reload" option is implemented then remove the
   # 'force-reload' alias
   #
   log_daemon_msg "Restarting $DESC" "$NAME"
   do_stop
   case "$?" in
     0|1)
      do_start
      case "$?" in
         0) log_end_msg 0 ;;
         1) log_end_msg 1 ;; # Old process is still running
         *) log_end_msg 1 ;; # Failed to start
      esac
      ;;
     *)
        # Failed to stop
      log_end_msg 1
      ;;
   esac
   ;;
  *)
   echo "Usage: ${SCRIPTNAME} {start|stop|status|restart|force-reload}" >&2
   exit 3
   ;;
esac

:
