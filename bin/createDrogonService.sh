#! /bin/sh -

# TODO
# implement
# if Freebsd then...
printf "Under Development.\n";
exit;
# This script is to be used with FreeBSD.
# You can learn more about FreeBSD here:
# https://docs.freebsd.org/en/books/handbook/

printf "Enter the domainname of the website (i.e. compcaly.com):";
read domain_name;
name=$(printf "%s" "${domain_name}" | sed 's/\./_/g');
capName=$(printf "%s" "${name}" | tr a-z A-Z);
app_name=$(printf "%s" "${name}" | sed 's/_/-/g');
printf "Enter the port to run this website on (i.e. 9000, 9500):";
read port;
printf "Enter the project's directory (i.e /opt):";
read project_dir;
appSecretVarName="APPLICATION_SECRET_${capName}"

# Old 
#appSecret=$(openssl rand -base64 70 | sed -e 's/\///g' | tr '\n' '@');
# Per the play guide #NOTE I keep getting errors when I run it on the
# command line continueally - character lengtch isn't consistent either
# per haps a while char length is not meant while loop might help
appSecret=$(head -c 70 /dev/urandom | base64 | head -c 70)
#TODO fix the tr pipe, it currently always returns '@' to replace line breaks
export ${appSecretVarName}='${appSecret}';
tee <<-EOF > "/usr/local/etc/rc.d/${app_name}";
#! /bin/sh -
# PROVIDE: ${name}
# REQUIRE: FILESYSTEMS

. /etc/rc.subr
export ${appSecretVarName}='${appSecret}';
port="${port}";
name="${name}";

rcvar="${name}_enable"
stop_cmd="${name}_stop"
start_cmd="${name}_start"
restart_cmd="${name}_restart"


${name}_clean()
{
  PID_file="${project_dir}/${domain_name}/target/universal/stage/RUNNING_PID";
  if [ -e \${PID_file} ];
  then
    kill \$(cat \${PID_file}) > /dev/null;
    rm -rf \${PID_file};
  fi
}

${name}_start()
{
  printf "Starting ${domain_name} on port: %s.\n" "\${port}";
  ${name}_clean;
  /usr/local/bin/bash ${project_dir}/${domain_name}/target/universal/stage/bin/${app_name} -Dhttp.port=\${port} -java-home "/usr/local/" > /dev/null&
}

${name}_stop()
{
  printf "Stopping ${domain_name}.\n";
  ${name}_clean;
}

${name}_restart()
{
  ${name}_stop;
  ${name}_start;
}

load_rc_config \${name}
run_rc_command "\$1"
EOF

chmod 555 "/usr/local/etc/rc.d/${app_name}";
printf "%s_enable=\"YES\"\n" "${name}" >> /etc/rc.conf
printf "Adding continue cron job to restart process in the event it dies";
printf "*/15  *   *   *   *  sh /opt/%s/continueKilledProcess.sh\n" "${domain_name}" >> /var/cron/tabs/root;
printf "The service for $domain_name has been created.\n";
