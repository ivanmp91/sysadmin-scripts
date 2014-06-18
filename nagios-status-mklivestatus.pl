#!/usr/bin/perl -w
# Script to get all the nagios alarms via mk-livestatus for services and hosts in status of Warning, 
# Critical or Uknown Where the notifications are enabled and the check is not acknowledged
# Fields select for each alarm:
# - host_name : Name of the host affected.
# - check_command : command executed by the check.
# - plugin_output : Output of the command.
# - last_hard_state : The current hard state of the alarm.
# - service_description : The description of the service setup on nagios.
# - last_state_change : Last time the check change of status.
#
# If the string option is enabled, the script print by output the next information for each alarm got:
# host_name - service_description : plugin_output [age of the alarm]
# If html is enabled then will generate an output in html with a table of two columns for each
# Alarm, one with the check command and the output with a background color of red, yellow or orange
# depending of the check status, and the second one the hostname affected with a url to the nagios
# page for the host. Edit the html to put your own stuff, this is only a simple template to show
# the alerts with a basic styles.

use strict;
use warnings;
use Monitoring::Livestatus;
use Carp;
use Getopt::Long;
use Time::Duration;

my ($html,$string);
my %alarms = (); # Store all the alarms
my $alarm_str = "";
my %nagios_status = (0 => 'ok', 1 => 'warning', 2 => 'critical', 3 => 'unknown'); # Association of the nagios status code
# Path to the unix socket
my $livestatus_socket = "/usr/local/nagios/var/rw/live";
# Open a new connection with mk-livestatus
my $ml = Monitoring::Livestatus->new(
      socket => $livestatus_socket
);

# Call Getopt long function.
GetOptions('html'  => \$html,
           'string' => \$string);

# Don't die if we've errors. We handle it later
$ml->errors_are_fatal(0);

# Get all services in Warning, Critical or Unknown states where notifications are enabled and not acknowledged
my $services = $ml->selectall_arrayref("GET services\nColumns: host_name check_command plugin_output last_hard_state service_description last_state_change\nFilter: acknowledged = 0\nFilter: notifications_enabled = 1\nAnd: 2\nFilter: last_hard_state = 2\nFilter: last_hard_state = 1\nFilter: last_hard_state = 3\nOr: 3",
{
	Slice => {},
        rename => { 'name' => 'host_name' }
});

# Get all hosts in Warning, Critical or Unknown states where notifications are enabled and not acknowledged
my $hosts = $ml->selectall_arrayref("GET hosts\nColumns: host_name plugin_output last_hard_state check_command last_state_change\nFilter: acknowledged = 0\nFilter: notifications_enabled = 1\nAnd: 2\nFilter: last_hard_state = 2\nFilter: last_hard_state = 1\nFilter: last_hard_state = 3\nOr: 3",
{
        Slice => {},
        rename => { 'name' => 'host_name' }
});

# Show errors if it found any
if($Monitoring::Livestatus::ErrorCode) {
        croak($Monitoring::Livestatus::ErrorMessage);
}

# Get all services alarms
foreach(@{$services}){
	my $service = $_;
	my $now = time;
	# Calculate alarm age
        my $age = duration($now - $service->{last_state_change});
	my $current_hostname = $service->{host_name};
	my $current_sdesc = $service->{service_description};
	# Populates hash with services alarms
	$alarms{$current_hostname}{$current_sdesc}{'hostname'} = $current_hostname;
        $alarms{$current_hostname}{$current_sdesc}{'service'} = $current_sdesc;
        $alarms{$current_hostname}{$current_sdesc}{'output'} = $service->{plugin_output};
        $alarms{$current_hostname}{$current_sdesc}{'age'} = $age;
	$alarms{$current_hostname}{$current_sdesc}{'status'} = $nagios_status{$service->{last_hard_state}};
	# Stores output message
	$alarm_str .= $current_hostname." - ".$current_sdesc.": ".$service->{plugin_output}." [$age]"."\n";
}

# Get all hosts alarms
foreach(@{$hosts}){
        my $host = $_;
        my $now = time;
	# Calculate alarm age
        my $age = duration($now - $host->{last_state_change});
        my $current_hostname = $host->{host_name};
        my $current_sdesc = $host->{check_command};
	# Populates hash with all the hosts alarms
        $alarms{$current_hostname}{$current_sdesc}{'hostname'} = $current_hostname;
        $alarms{$current_hostname}{$current_sdesc}{'service'} = $current_sdesc;
        $alarms{$current_hostname}{$current_sdesc}{'output'} = $host->{plugin_output};
        $alarms{$current_hostname}{$current_sdesc}{'age'} = $age;
	$alarms{$current_hostname}{$current_sdesc}{'status'} = $nagios_status{$host->{last_hard_state}};
	# Stores output message
        $alarm_str .= $current_hostname." - ".$current_sdesc.": ".$host->{plugin_output}." [$age]"."\n";
}

# Print out alarms in the chosen format
if (%alarms && $string) {
        print $alarm_str, "\n";
}elsif(%alarms && $html){
	my $alarm_html = "";
	foreach my $host (keys %alarms){
		foreach my $service (keys %{$alarms{$host}}){
			$alarm_html.="<tr>";
			$alarm_html.="<td class=\"nagios-$alarms{$host}{$service}{'status'}\">";
			$alarm_html.=$alarms{$host}{$service}{'service'}." : $alarms{$host}{$service}{'output'} - $alarms{$host}{$service}{'age'}";
			$alarm_html.="</td>";
			$alarm_html.="<td class=\"table-body\">";
			$alarm_html.="<a href='http://nagios.yourdomain.com/cgi-bin/status.cgi?host=$alarms{$host}{$service}{'hostname'}' target='_blank'> $alarms{$host}{$service}{'hostname'}</a>";
			$alarm_html.="</td>";
			$alarm_html.="</tr>";
		}
	}
	my $html = qq{
	<html>
	<head>
		<title>Nagios Alarms</title>
		<style>
			.nagios-critical {background-color: #F78181;}
			.nagios-warning {background-color: #F3F781;}
			.nagios-unknown {background-color: #F5DA81;}
			.table-title {background-color: #E0F8F7;}
			.table-body {background-color: #E0F8F7;}
		</style>
	</head>
	<body>
		<table align="center" border="0" cellpadding="4" cellspacing="1" width="100%">
        		<thead>
          		<tr>
				<td colspan="0" class="table-title"><strong><a href="https://nagios.yourdomain.com/">Alarms</a></strong></td>
          		</tr>
        		</thead>
        		<tbody>
                		$alarm_html
        		</tbody>
      		</table>
	</body>
	</html>
	};
	print $html;
}
exit 0;
