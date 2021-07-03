#! /bin/sh -

# Variables
binDir="bin";
installer="installer.sh";
installerLocation="${binDir}/${installer}";

while getopts :cd:hs OPT; do
  case "X$OPT" in
    "Xc"|"X+c")
      # Give computer time to boot.
      sleep 60;
      sh getNetworkStatus.sh
      ;;
    "Xd"|"+d")
      repoDir="$OPTARG";
      ;;
    "Xh"|"X+h")
            cat <<EOF
Use this script to update software on reboot.

-c 
    Use this option to execute the sript from cron during reboot.
    We are using reboot because we are assuming we are on a laptop.

-d
    Use this option to specity the directory of the repository you 
    would like to update.
-h
    Display this usage.

-s 
    Use this option to update a submodule.

NOTE:
This script has only been tested on Mac OS X.

BUGS:
This software is in beta stage and it is subject to change and prone to errors.

EOF
      exit 0;

      ;;
    "Xs"|"X+s")
      gitCommand="git submodule pull --rebase --stat origin main";
      ;;

    *)
      printf "usage: %s [-chs] [-d /opt/projectDirectory ]\n" "$(basename $0)";
      exit 2
  esac
done
shift $(expr $OPTIND - 1)
OPTIND=1

if [ -z "$repoDir" ];
then
  printf "Enter the directory of the repo you are Trying to update.\n";
  printf "(ex. /opt/rubbish,/opt/newProject): ";
  read repoDir
  
fi
projectName="${repoDir##*/}";
projectNameAppend="$(tr '[:lower:]' '[:upper:]' <<< ${projectName:0:1})${projectName:1}"


if [ -z "$gitCommand" ];
then
  gitCommand="git pull --rebase --stat origin main";
fi

# This script is borrowed from oh-my-zsh's upgrade script. Why reinvent the wheel.

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
cd "$repoDir";

if eval "$gitCommand"
then
  if [ -e "${installerLocation}" ];
  then
    chmod u+x "${installerLocation}";
    cd "${binDir}";
    sh "${installer}";
  fi
  printf '%s' "$GREEN"
  sh $(dirname $0)/get${projectNameAppend}UpdaterText.sh
  printf "${BLUE}%s\n" "Cowabunga Dude! The $projectName has been updated and/or is at the current version."
else
  printf "${RED}%s${NORMAL}\n" 'There was an error updating. Try again later?'
fi
