#! /bin/sh -
# Variables
user="$(whoami)";
dir="$(dirname $0)";
updater="${dir}/updater.sh";
firstCrontabWidth=10;
secondCrontabWidth=10;
tmpCrontab="/var/tmp/crontab.tmp";

chmod -R u+x "$dir";

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
ossp-uuid
zlib
openssl@1.1
c-ares
boost
sqlite
mariadb
hiredis
EOF)"

OLDIFS=$IFS;
IFS=$'\n';
for dep in ${deps};
do
  isDepInstalled=$(brew ls --versions $dep);
  # TODO
  # determine gcc version is greater than 5.4.0
  # determine cmake version is greater than 3.5
  # there seems to be a problem with boost Drogon
  # is unable to detect it is installed.
  # 
  if [ -z "${isDepInstalled}" ];
  then
    # Used for dep prerequisites
    case $dep in
      mariadb)
	brew unlink mysql
	;;
    esac
    brew install $dep;
    case $dep in
      git)
        git config --global user.name "$(id -F)";
	printf "Enter email account (ex. username@gmail.com): ";
	read emailAddress;
	git config --global user.email "emailAddress";
	# set the default conflict resolution.
	git config pull.rebase false;
	# set default branch to main since git now complains if it is master.
	defaultBranch=main
	git config --global init.defaultBranch $defaultBranch
	# TODO 
	# walk user through github ssh setup
	;;
      gh)
	gh auth login;
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

optDir="/opt":
# TODO 
# test this, this might fail if the directory already exists
if ! mkdir -p "$optDir" 2>/dev/null;
then
  sudoCommands="$(
tee <<EOF
mkdir -p $optDir;
chown -R $user /opt;
EOF)"
  if ! sudo -s eval "$sudoCommands" 2>/dev/null;
     then
     repoDir="${HOME}/${optDir}";
  fi
  mkdir -p "$optDir";
fi

cd $optDir;
git clone https://github.com/an-tao/drogon;
cd drogon;
git submodule update --init;
mkdir build;
cd build;
cmake -DOPENSSL_ROOT_DIR=/usr/local/opt/openssl -DOPENSSL_LIBRARIES=/usr/local/opt/openssl/lib -DCMAKE_BUILD_TYPE=Release ..;
make && sudo make install;

# add updater to cron
# adding update to reboot because, in can be installed in a laptop.
if [ -z "$(crontab -l 2>/dev/null | grep $updater)" ];
then
  crontab -l 2>/dev/null > $tmpCrontab;
  printf "%-${firstCrontabWidth}s%-${secondCrontabWidth}s%s\n" \
	 "@reboot" "/bin/sh" "$updater -c";
  tee $tmpCrontab | crontab -;
  rm $tmpCrontab;
fi
rm -rf $optDir/drogon;
