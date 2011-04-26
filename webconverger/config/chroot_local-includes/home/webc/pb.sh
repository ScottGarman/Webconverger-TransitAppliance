#!/bin/sh
# pb = persistent browser
# Keep the browser running and clean between sessions in ~webc
# hendry@webconverger.com
WEBCHOME=/home/webc

# disable bell
xset b 0 0

# disable screensaver
xset -dpms s off

# white background
xsetroot -solid "#ffffff"

# only when noroot is supplied, we use Webc's WM dwm.web
grep -qs noroot /proc/cmdline && /usr/bin/dwm.web || /usr/bin/dwm.default &

# hide the cursor by default, showcursor to override
grep -qs showcursor /proc/cmdline || /usr/bin/unclutter &

# Stop (ab)users breaking the loop to restart the exited browser
trap "echo Unbreakable!" SIGINT SIGTERM

for x in $(cat /proc/cmdline); do
	case $x in
		homepage=*)
		set -f -- $(/bin/busybox httpd -d ${x#homepage=})
		;;
		kioskresetstation=*) # For killing the browser after a number of minutes of idleness
		/usr/bin/kioskresetstation ${x#kioskresetstation=} &
		;;
	esac
done

grep -qs compose /proc/cmdline && setxkbmap -option "compose:rwin" && logger "Compose key setup"

# Set default homepage if homepage cmdline isn't set
test $1 || set -- "http://portal.webconverger.com/"

# if no-x-background is unset, try setup a background from homepage ($1)
grep -qs noxbg /proc/cmdline || {
wget --timeout=5 $1/bg.png -O $WEBCHOME/bg.png ||
cp /etc/webconverger/webconverger.png $WEBCHOME/bg.png
xloadimage -quiet -onroot -center $WEBCHOME/bg.png
}

# No screen blanking (warning: might limit the life span of your screen & world)
grep -qs noblank /proc/cmdline && xset s off && xset -dpms && logger noblank

while true
do

	if test -x /usr/bin/iceweasel
	then
		rm -rf $WEBCHOME/.mozilla/
		iceweasel $@
		rm -rf $WEBCHOME/.mozilla/
	fi

	if test -x /usr/bin/google-chrome
	then
		rm -rf $WEBCHOME/.cache/
		rm -rf $WEBCHOME/.config/

		for x in $(cat /proc/cmdline)
		do
			case $x in
			http_proxy=*)
			HTTP_PROXY="--proxy-server=${x#http_proxy=}"
			;;
			esac
		done

		if test -f /etc/issue.webc
		then
			google-chrome -kiosk $HTTP_PROXY --no-first-run --user-agent="$(cat /etc/issue.webc)" --homepage="$1" $@
		else
			google-chrome -kiosk $HTTP_PROXY --no-first-run --homepage="$1" $@
		fi

		rm -rf $WEBCHOME/.cache/
		rm -rf $WEBCHOME/.config/
	fi

	if test -x /usr/bin/opera
	then
		rm -rf $WEBCHOME/.opera/
		opera -k -noprint -kioskresetstation -kioskwindows -nomenu -nohotlist -resetonexit -nosave -e $@
		rm -rf $WEBCHOME/.opera/
	fi

	rm -rf $WEBCHOME/.adobe
	rm -rf $WEBCHOME/.macromedia
	rm -rf $WEBCHOME/Downloads

done
