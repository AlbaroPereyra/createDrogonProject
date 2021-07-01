#! /bin/sh -

projectName="createProject";
projectDir="$(dirname $0)";
projectDir=${projectDir%/*};

while getopts :hc OPT; do
  case $OPT in
    h|+h)
            cat <<EOF
Use this script to update this software on reboot.
It can be more modular, dynamic but it is what it 
is for now.

-h
    Display this usage.
-c 
    Use this option to execute the sript from cron during reboot.
    We are using reboot because we are assuming we are on a laptop.

NOTE:
This script has only been tested on Mac OS X.

BUGS:
This software is in beta stage and it is subject to change and prone to errors.

EOF
      exit 0;

      ;;
    c|+c)
      # Give computer time to boot.
      sleep 60;
      ./getNetworkStatus.sh
      ;;
    *)
      echo "usage: `basename $0` [+-hc} [--] ARGS..."
      exit 2
  esac
done
shift `expr $OPTIND - 1`
OPTIND=1


# This script is borrowed from on-my-zsh's upgrade script. Why reinvent the wheel.

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1;
then
  ncolors=$(tput colors);
fi

# -t is used to verify an output exists, 2 is for stderr etc.
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ];
then
  RED="$(tput setaf 1)";
  GREEN="$(tput setaf 2)";
  YELLOW="$(tput setaf 3)";
  BLUE="$(tput setaf 4)";
  BOLD="$(tput bold)";
  NORMAL="$(tput sgr0)";
else
  RED="";
  GREEN="";
  YELLOW="";
  BLUE="";
  BOLD="";
  NORMAL="";
fi

printf "${BLUE}%s${NORMAL}\n" "Updating $projectName.";
cd "$projectDir";

#TODO 
# update and install drogon submodule.

if git pull --rebase --stat origin main;
then
  printf '%s' "$GREEN"
  printf '%s\n' '  ______  ______   ______            '
  printf '%s\n' ' |  ____\ |     \ |  __  \           '
  printf '%s\n' ' | /      |  |  | |  ____/           '
  printf '%s\n' ' | \_____ |  |  | | |                '
  printf '%s\n' ' |______/ |_____/ |_|      Essentials'
  printf '%s\n' '                                     '
  printf "${BLUE}%s\n" "Cowabunga Dude! The Alamo Server Wizard has been updated and/or is at the current version."
else
  printf "${RED}%s${NORMAL}\n" 'There was an error updating. Try again later?'
fi
