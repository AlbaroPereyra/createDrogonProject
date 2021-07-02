#! /bin/sh -

# Variables
dir="$(dirname $0)";
projectDir=${dir%/*};
updater="$dir/updater.sh -c -d ${projectDir}";
tmpCrontab="/var/tmp/crontab.tmp";
projectName="createDrogonProject";
#TODO get this value dinamicaly
exeName="createDrogonProject";
manDir="/usr/local/share/man/man1";
manFileExtension=".1";
manPage="$manDir/${exeName}${manFileExtension}";
drogonDir="/opt/drogon";

while getopts :h OPT; do
  case "X$OPT" in
    "Xh"|"X+h")
        tee <<EOF
Use this script to uninstall $projectName

NOTE:
This script has only been tested on Mac OS X.
EOF
  exit 0;
      ;;
    *)
      printf "usage: $(basename $0) [-h]\n";
      exit 2;
  esac
done
shift $(expr $OPTIND - 1);
OPTIND=1;

# remove updater from cron
crontab -l 2>/dev/null | grep -v "$updater" > $tmpCrontab;
cat "$tmpCrontab" | crontab -
rm "$tmpCrontab";
rm -rf "mapPage";
#remove drogon
rm -rf "$drogonDir";
# self destruct
rm -rf "$projectDir";

