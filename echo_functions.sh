#! /bin/bash

# Get a sane screen width
[ -z "${COLUMNS:-}" ] && COLUMNS=80
 
if [ -f /etc/sysconfig/i18n -a -z "${NOLOCALE:-}" ] ; then
  . /etc/profile.d/lang.sh
fi

# Read in our configuration
if [ -z "${BOOTUP:-}" ]; then
    # This all seem confusing? Look in /etc/sysconfig/init,
    # or in /usr/doc/initscripts-*/sysconfig.txt
    BOOTUP=color
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
    SETCOLOR_NORMAL="echo -en \\033[0;39m"
    LOGLEVEL=1
fi


echo_success() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
  echo -n $"  OK  "
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 0
}
 
echo_failure() {
  [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
  echo -n "["
  [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
  echo -n $"FAILED"
  [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
  echo -n "]"
  echo -ne "\r"
  return 1
}

# Log that something succeeded
success() {
  [ "$BOOTUP" != "verbose" -a -z "${LSB:-}" ] && echo_success
  return 0
}
 
# Log that something failed
failure() {
  local rc=$?
  [ "$BOOTUP" != "verbose" -a -z "${LSB:-}" ] && echo_failure
  [ -x /usr/bin/rhgb-client ] && /usr/bin/rhgb-client --details=yes
  return $rc
}

action() {
  local STRING rc
 
  STRING=$1
  echo -n "$STRING "
  if [ "${RHGB_STARTED:-}" != "" -a -w /etc/rhgb/temp/rhgb-console ]; then
      echo -n "$STRING " > /etc/rhgb/temp/rhgb-console
  fi
  shift
  "$@" && success $"$STRING" || failure $"$STRING"
  rc=$?
  echo
  if [ "${RHGB_STARTED:-}" != "" -a -w /etc/rhgb/temp/rhgb-console ]; then
      if [ "$rc" = "0" ]; then
      	echo_success > /etc/rhgb/temp/rhgb-console
      else
        echo_failure > /etc/rhgb/temp/rhgb-console
	[ -x /usr/bin/rhgb-client ] && /usr/bin/rhgb-client --details=yes
      fi
      echo > /etc/rhgb/temp/rhgb-console
  fi
  return $rc
}
