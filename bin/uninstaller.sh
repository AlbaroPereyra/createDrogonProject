#! /bin/sh -

# Variables
dir="$(dirname $0)";
updater="$dir/updater.sh";
tmpCrontab="/var/tmp/crontab.tmp";
projectDir=${dir%/*};
projectName="createDrogonProject";
#TODO get this value dinamicaly
exeName="createDrogonProject";
manDir="/usr/local/share/man/man1";
manFileExtension=".1";
manPage="$manDir/${exeName}${manFileExtension}";


while getopts :h OPT; do
  case $OPT in
    h|+h)
        tee <<EOF
Use this script to uninstall $projectName

NOTE:
This script has only been tested on Mac OS X.
EOF
  exit 0;
      ;;
    *)
      printf "usage: $(basename $0) [+-h] [--] ARGS...\n";
      exit 2;
  esac
done
shift $(expr $OPTIND - 1);
OPTIND=1;

# remove updater from cron
crontab -l 2>/dev/null | grep -v "$updater" > $tmpCrontab;
cat "$tmpCrontab" | crontab -
rm $tmpCrontab
rm -rf "mapPage";
# self destruct
rm -rf "$projectDir";
#TODO remove drogon
