# Nagios Plugins

- `local`: Execution is done on the host, through `check_nrpe` or `check_by_ssh`;
- `snmp` : Execution is done from Shinken (or Nagios, etc.) host.

Three types of files:

- `*.sh` : The actual shell script (To put in `/usr/local/nagios/libexec`)
- `*.php`: The Pnp4Nagios template (To put in `/usr/local/pnp4nagios/templates`)
- `*.png`: A sample graph output

