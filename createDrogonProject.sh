#! /bin/sh -

# Variables
# Get script directory used to locate templates
dir="$(dirname $0)";
script="$dir/$(basename $0)";
exeName="$(expr $script : '.*/\(.*\)\..*')";
todaysDate="$(date +%m%d%Y)";
# TODO help user update this information
private="false";
public="true";
user="$(whoami)";

# Disclaimer
printf "WARNING:\n";
printf "Do not use this script it is currently under development\n";
exit 1;
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
  case $OPT in
    h|+h)
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
    n|+n)
      softwareName="$OPTARG";
      ;;

    p|+p)
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

# -s returns 0 if found otherwise 1
which -s brew;
# $? exit status of previous command
if [ $? != 0 ];
then
  # Install Homebrew
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
fi
brew update;
brew upgrade;

deps="$(
tee <<EOF
git
gh
gcc
cmake
jsoncpp
util-linux
zlib
openssl@1.1
c-ares
boost
sqlite
mariadb
EOF)"

OLDIFS=$IFS;
IFS=$'\n';
for dep in ${deps};
do
  # TODO
  # determine gcc version is greater than 5.4.0
  # determine cmake version is greater than 3.5
  # 
  isDepInstalled=$(brew ls --versions $dep);
  if [ -z "${isDepInstalled}" ];
  then
    case $dep in
       mariadb)
	 brew unlink mysql
	;;
    esac
    brew install $dep;
    case $dep in
      # TODO add git to case
      # prompt user for global git defults
      # user.name=Albaro Pereyra
      # user.email=2AlbaroPereyra@gmail.com
      # including renaming master now to main
      # defaultBranch=main
      #git config --global init.defaultBranch $defaultBranch
      # Also maybe walk user though github ssh setup
      gh)
	gh auth login;
	;;
      util-linux)
	# TDOO
	# Notes::
	# util-linux is a keg-only package and will not be symlinked to
	# /usr/local. Hence you will have to specify the following path
	# when prompted for uuid installation directory
	# /usr/local/opt/util-linux
	printf "/usr/local/opt/util-linux" | pecl install uuid
	;;
      zlib)
	export LDFLAGS="-L/usr/local/opt/zlib/lib";
	export CPPFLAGS="-I/usr/local/opt/zlib/include";
	export PKG_CONFIG_PATH="/usr/local/opt/zlib/lib/pkgconfig";
	;;
    esac
  fi
done
IFS=$OLDIFS;

if [ -z "$softwareName" ];
then
  # prompt for repo dir
  printf "Enter softwareName(i.e rubbish, bestSoftware etc.): ";
  read softwareName;
fi

repoDir="/opt/${softwareName}"
if ! mkdir -p "$repoDir" 2>/dev/null;
then
  sudoCommands="$(
tee <<EOF
mkdir -p /opt;
chown -R $user /opt;
EOF)"
  if ! sudo -s eval "$sudoCommands" 2>/dev/null;
     then
     repoDir="${HOME}/${repoDir}";
  fi
  mkdir -p "$repoDir";
fi

# Create repo in Github
gitDir="${repoDir}/.git/";
mkdir -p ${gitDir};
cd $repoDir;
gh repo create --confirm --enable-issues=true --enable-wiki=false --private="$private" --public="$public" "$softwareName";
git --git-dir="${gitDir}" --work-tree="${repoDir}" init;
git --git-dir="${gitDir}" --work-tree="${repoDir}" add -A "${repoDir}";
git --git-dir="${gitDir}" --work-tree="${repoDir}" commit -m "Initial commit ${todaysDate}";
defaultBranch="$(git config --global --get init.defaultBranch)";
git --git-dir="${gitDir}" --work-tree="${repoDir}" push --set-upstream origin "$defaultBranch";

git clone https://github.com/an-tao/drogon $repoDir
git submodule update --init
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release
make && sudo make install
