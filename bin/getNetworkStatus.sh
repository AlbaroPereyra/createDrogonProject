#! /bin/sh -

# Variables
localHost="127.0.0.1";
routableIP="8.8.8.8";
defaultGateway="";
pingableHost="scanme.nmap.org";

# Determine if online.
if [ -z "$(ping -oq $localHost 2>/dev/null | sed -e '/^PING.*$/d' -e '/^$/d' )" ];
then
  printf "WARNING:\n\
  Unable to ping: $localHost\n\
  This might be due to your local firewall settings.\n" >&2&
fi
commandOutput=$(route -nv get $routableIP 2>/dev/null | grep -E '^.*gateway:.*' | awk '{printf "%s\n" ,$2}');
# Set couter to 0
count=0
# Give computer time to connect: 2 hours
maxCount=7200;
if [ -z "$commandOutput" ];
then
  # Let user know what is going on first time around
  printf "Waiting for routing infomation to: %s\n" "$routableIP";
  # Do until loop
  until [ -n "$commandOutput" ];
  do
    printf ".";
    count=$(expr count+1);
    commandOutput=$(route -nv get $routableIP 2>/dev/null | grep -E '^.*gateway:.*' | awk '{printf "%s\n" ,$2}'  );
    sleep 1;
    if [ $count = $maxCount ];
    then
      # printf to the error output
      printf "\nUnable to get routing information to: $routableIP\n" >&2&
      exit 1;
    fi
  done;
  printf "\n";
fi
# Set default gateway
defaultGateway="$commandOutput";
if [ -z "$(ping -oq $defaultGateway 2>/dev/null | sed -e '/^PING.*$/d' -e '/^$/d' )" ];
then
  printf "WARNING:\n\
  Unable to ping: $defaultGateway\n\
  This might be due to the settings on your Default Gateway.\n" >&2&
fi
if [ -z "$(ping -dDoq $pingableHost -m 255 -k CTL -p ff 2>/dev/null | sed -e '/^PING.*$/d' -e '/^$/d')" ];
then
  printf "WARNING:\n\
  Unable to ping: $pingableHost\n\
  This might be due to your local firewall settings.\n" >&2&
fi
