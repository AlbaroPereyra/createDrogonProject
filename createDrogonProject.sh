#! /bin/sh -

# Variables
dir="$(dirname $0)";
script="$dir/$(basename $0)";
binDir="$dir/bin";
installer="installer.sh";
exeName="$(expr $script : '.*/\(.*\)\..*')";
todaysDate="$(date +%m%d%Y)";
private="false";
public="true";
user="$(whoami)";
optDir="/opt";

# Disclaimer
printf "WARNING:\n";
printf "This software is in beta, subject to change and prone to errors.\n";

# Get arguments:
# I personally enjoy doing this first. That being said if you are
# using functions or need to refer to variables not yet assigned
# you can get into a lot of trouble it is recomended to do this
# at the end of the shell script.
#
# Note:
# if the option has an argument add a ':' after the option.
while getopts :hl:n:p OPT; do
  case "X$OPT" in
    "Xh"|"X+h")
      cat <<EOF
Use this script to create a new Drogon project.
You can learn more about Drogon here:
https://drogon.docsforge.com/master/overview/

-h
    Display this usage.

-n [(cammelCase name of software)]
    Use this option to specifie the name of the software.   
-p
    Use this option to make the repository private.

NOTE:
This script has only been tested on Mac OS X.

BUGS:
This software is in beta stage and it is subject to change and prone to errors.

EOF
      exit 0;
      ;;
    "Xn"|"X+n")
      softwareName="$OPTARG";
      ;;

    "Xp"|"X+p")
      private=true;
      public=false;
      ;;
    *)
      printf "usage: %s [-hp] [-n (cammelCase program name)]\n" "$exeName" >&2;
      exit 2;
  esac
done
shift $(expr $OPTIND - 1)
OPTIND=1

which -s drogon_ctl;
# $? exit status of previous command
if [ $? != 0 ];
then
  # Install Drogon
  chmod u+x ${binDir}/${installer};
  sh ${binDir}/${installer}
fi


if [ -z "$softwareName" ];
then
  # prompt for repo dir
  printf "Enter softwareName(i.e rubbish, bestSoftware etc.): ";
  read softwareName;
fi
repoDir="${optDir}/${softwareName}";

# Create repo on Github
gitDir="${repoDir}/.git/";
cd $optDir;
gh repo create --confirm --enable-issues=true --enable-wiki=true --private="$private" --public="$public" "$softwareName";
cd "$repoDir";
drogon_ctl create project $softwareName;
# This can probably be cleaner with find.
cp -R "${softwareName}/" "${repoDir}";
rm -rf "${softwareName}/";
cd build;
cmake -DOPENSSL_ROOT_DIR=/usr/local/opt/openssl -DOPENSSL_LIBRARIES=/usr/local/opt/openssl/lib -DCMAKE_BUILD_TYPE=Release ..;
make;
./$softwareName
