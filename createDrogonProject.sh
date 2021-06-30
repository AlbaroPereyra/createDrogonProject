#! /bin/sh -

# Variables
# Get script directory used to locate templates
dir="$(dirname $0)";
script="$dir/$(basename $0)";
exeName="$(expr $script : '.*/\(.*\)\..*')";
todaysDate="$(date +%m%d%Y)";
# TODO help user update this information
username="$(id -F)";
year="$(date +%Y)";
private="false";
public="true";
force=false;
user="$(whoami)";

# Disclaimer
printf "WARNING:"
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
while getopts :fhl:n:p OPT; do
  case $OPT in
    f|+f)
      license="bsd";
      forceLicense=true;
      ;;
    h|+h)
      cat <<EOF
Use this script to create a new Drogon project.
You can learn more about Drogon here:
https://drogon.docsforge.com/master/overview/

-f
    Use this option to force the default license which is:
    BSD 3-clause license.
-h
    Display this usage.
-l [GPL3|GPL2|BSD]
    Use this option to select one of the following licenses.
    GPL2: Recommended for open source software.
          More information can be found here:
          
    GPL3: Recommended for the extreme left.
          More information can be found here:
    BSD:  Recommended for everything else.
          More information can be foudn here:
          https://en.wikipedia.org/wiki/BSD_licenses
    The following system variables will be used, except for GPL3:
    Name:     $username
    Year:     $year
-n [(cammelCase name of software)]
    Use this option to specifie the name of the software.   
-p
    Use this option to make the repository private.

NOTE:
This script has only been tested on Mac OS X.

BUGS:
This software is in beta stage and it is subject to change and prone to errors.

DISCLAIMER:
The information provided on this software does not, and is not intended to, constitute legal advice; instead, all information, content, and materials available on this software are for general informational purposes only.  Information on this software may not constitute the most up-to-date legal or other information.  This software contains mentions to other third-party licenses.  Such licenses are only for the convenience of the reader, user; We and its contributors do not recommend or endorse the contents of the third-party sites.

Readers of this software should contact their attorney to obtain advice with respect to any particular legal matter.  No reader, or user of this software should act or refrain from acting on the basis of information on this software without first seeking legal advice from counsel in the relevant jurisdiction.  Only your individual attorney can provide assurances that the information contained herein – and your interpretation of it – is applicable or appropriate to your particular situation.  Use of, and access to, this software or any of the mentions or resources contained within the software do not create an attorney-client relationship between the reader, or user and software authors, contributors, contributing law firms, or committee members and their respective employers. 

The views expressed at, or through, this software are those of the individual authors writing in their individual capacities only – not those of their respective employers, we, or committee/task force as a whole.  All liability with respect to actions taken or not taken based on the contents of this software are hereby expressly disclaimed.  The content on this software is provided "as is;" no representations are made that the content is error-free.
EOF
      exit 0;
      ;;
    l|+l)
      license="$OPTARG";
      ;;
    n|+n)
      softwareName="$OPTARG";
      ;;

    p|+p)
      private=true;
      public=false;
      ;;
    *)
      printf "usage: %s [-fhp] [-l GPL3|GPL2|BSD] [-n (cammelCase program name)]\n" "$exeName" >&2;
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

licenseFile="${repoDir}/license.txt";
# copy license
licese=$(printf "%s" "$license" | tr '[:upper:]' '[:lower:]');
case $license in
  gpl2)
    printf "Enter a description of what your sofware does.\n"
    printf "ex. This software is used to create software.\n";
    read programDescription
    printf "%s,%s\n" "$programNmae" "programDescription"> "$licenseFile";
    # This line is ugly, but it works, alternatively we can evaluate and write line by line.
    eval "echo \"$(< templates/licenses/GPL2.txt)\"" >> "$licenseFile";
    ;;
  gpl3)
    printf "Enter a description of what your sofware does.\n"
    printf "ex. This software is used to create software.\n";
    read programDescription
    printf "%s,%s\n" "$programNmae" "programDescription"> "$licenseFile";
    printf "Are you poor?\n";
    printf "If you type Y or y for yest:\n.";
    printf "The program will wave your right to sue.\n";
    printf "And copyright will be issued to the FSF community.\n";
    old_stty_cfg=$(stty -g)
    stty raw -echo
    poor=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
    stty $old_stty_cfg
    if printf "$poor" | grep -iq "^y" ;
    then
      printf "Aren't we all...\n";
      username="FSF";
    fi
    # This line is ugly, but it works, alternatively we can evaluate and write line by line.
    eval "echo \"$(< templates/licenses/GPL3.txt)\"" >> "$licenseFile";
    ;;
  *)
    if [ !$force ];
    then
      printf "Would you like your software software to be licensed\n";
      printf "under the BSD license? (press y for yes or n for no.)\n"
      old_stty_cfg=$(stty -g)
      stty raw -echo
      bsdLicense=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
      stty $old_stty_cfg
      if printf "$bsdLicense" | grep -iq "^n" ;
      then
	printf "We do not create unlicensed software here.\n" >&2;
	exit 2;
      fi
    fi
    # This line is ugly, but it works, alternatively we can evaluate and write line by line.
    eval "echo \"$(< templates/licenses/BSD_3-clause_license.txt)\"" > "$licenseFile";
    ;;
esac

# copy .gitignore file
cp $dir/templates/git/gitIgnore.txt "$repoDir"/.gitignore;

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

# git clone https://github.com/an-tao/drogon
# cd drogon
# git submodule update --init
# mkdir build
# cd build
# cmake -DCMAKE_BUILD_TYPE=Release..
# make && sudo make install
