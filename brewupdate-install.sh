#!/bin/bash
# ############################################################################
# NAME: brewupdate-install.sh
# DESC: Script to setup launchd process to update, upgrade and check (doctor)
#       for brew.
#
# LOG:
# yyyy/mm/dd [user] [version]: [notes]
# 2014/10/15 cgwong v0.1.0: Initial creation from https://github.com/mkalmes/brewupdate/blob/develop/brewupdate-install.sh
# 2015/01/07 cgwong v0.2.0: Added check for successful load.
# 2018/11/05 mrnilz v0.3.0: install local files instead of remote one
# 2021/01/29 koenichiwa v0.4.0: Added interval option
# ############################################################################

set -e

UPDATE_SCRIPT="/usr/local/bin/brewupdate.sh"
AGENTS="$HOME/Library/LaunchAgents"
PLIST="$AGENTS/net.brewupdate.agent.plist"
LOG="$HOME/Library/Logs/Homebrew/brewupdate"


[ -f "$PLIST" ] && launchctl unload "$PLIST"

if [ "$1" == "uninstall" ]; then
  rm -f "$PLIST" "$UPDATE_SCRIPT"
  if [ $? -eq 0 ]; then
    echo "Unloaded brewupdate."
    exit 0
  else
    echo "Failed unloading brewupdate!!"
    exit 1
  fi
fi

if [[ $1 == "interval" ]]; then
    if ! brew list --versions xmlstarlet > /dev/null;then
	brew install xmlstarlet
	echo "Installed xmlstarlet."
    fi

    xmlstarlet ed -s "//plist/dict" -t elem -n dict\
	       net.brewupdate.agent.plist.temp > net.brewupdate.agent.plist

## Checking prefered time

    echo "Give an CalendarInterval to run brew."
    echo "See https://www.manpagez.com/man/5/launchd.plist/ for more information."
    echo "Everything but sensical integers will be ignored." #TODO
    echo ""
    
    read -p "Month (1-12): " month
    if [[ "$month" =~ ^[0-9]+$ ]] && (($month <= 12)) && (($month >= 1)); then
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n key -v Month\
       		   net.brewupdate.agent.plist
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n integer -v $month\
		   net.brewupdate.agent.plist
    fi
    
    read -p "Weekday (0-7) (0 & 7 are Sunday): " weekday
    if [[ "$weekday" =~ ^[0-9]+$ ]] && (($weekday <= 7)) && (($weekday >= 0)); then
	xmlstarlet ed -L  -s "//plist/dict/dict[2]" -t elem -n key -v Weekday\
       		   net.brewupdate.agent.plist
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n integer -v $weekday\
      		   net.brewupdate.agent.plist
    else
	read -p "Day (1-31): " day
	if [[ "$day" =~ ^[0-9]+$ ]] && (($day <= 31)) && (($day >= 1)); then
	    xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n key -v Day\
		       net.brewupdate.agent.plist
	    xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n integer -v $day\
      		       net.brewupdate.agent.plist
	fi
    fi
    
    read -p "Hour (0-24): " hour
    if [[ "$hour" =~ ^[0-9]+$ ]] && (($hour <= 24)) && (($hour >= 0)); then
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n key -v Hour\
  		   net.brewupdate.agent.plist
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n integer -v $hour\
      		   net.brewupdate.agent.plist
    fi
    
    read -p "Minute (0-60): " minute
    if [[ "$minute" =~ ^[0-9]+$ ]] && (($minute < 60)) && (($minute >= 0)); then
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n key -v Minute\
		   net.brewupdate.agent.plist
	xmlstarlet ed -L -s "//plist/dict/dict[2]" -t elem -n integer -v $minute\
      		   net.brewupdate.agent.plist
    fi
fi

## add StandardOutPath and StandardErrorPath to plist
sed -i '' -e "s|@USERHOME@|$HOME|g" "$PLIST"
cp net.brewupdate.agent.plist "$AGENTS"
[ -f "$PLIST" ] && launchctl load "$PLIST"
if [ $? -eq 0 ]; then
  echo "Loaded brewupdate."
else
  echo "Failed loading brewupdate!!"
  exit 1
fi

if [ -z $1 ]; then
    cp brewupdate.sh /usr/local/bin
    if ! brew list --versions terminal-notifier > /dev/null;then
	brew install terminal-notifier
	echo "Installed terminal-notifier."
    fi
fi

## create log folder
mkdir -p $LOG

exit 0
