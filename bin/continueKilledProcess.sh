#! /bin/sh -

#TODO implement
printf "Under development\n";
exit 0;


if [ "X-h" == "X$1" ];
then
  cat <<EOF
help stuff.
EOF
  exit 0;
elif [ -z "$1" ];
then
  printf "Enter the name of the website (ex compcaly.com): ";
  read website
else
  website="$1";
fi

service=$(printf "%s" "${website}" | sed 's/\./-/g');

commandOutput=$(ps -o pid,command | grep ${website});
if [ -z "$commandOutput" ];
then
  service ${service} start;
  logger "Process $service restarted"&
  ps -aux >> /var/log/overload.log&
else
  printf "Process is running...\n" >&2&
fi
