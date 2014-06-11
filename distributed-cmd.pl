#!/usr/bin/env perl

use strict;
use warnings;
use Net::SSH::Perl;
use Getopt::Long;

my $user;
my @hosts;
my $check;
my $command;

my $params={}; #Stores the parameters

GetOptions($params,
	"hosts=s{1,}" =>\@hosts,
	"check:s"=>\$check,
	"user:s"=>\$user,
	"command:s"=>\$command,
	"help",
	) or die &usage;


&usage unless not defined $params->{help} and  defined $check and defined $command;

my $check_cmd = "$check > /dev/null 2>&1";
$user = "root" if not defined $user;

foreach(@hosts){
	my $host=$_;
	my $ssh = Net::SSH::Perl->new("$host");
	eval{$ssh->login("$user");};

	if (!$@){
		print "####### ".$host." #######\n";
		my ($stdout, $stderr, $exit) = $ssh->cmd("$check_cmd && (echo Running' $command' ; $command) && echo '$command run successfully'");
		if(defined($stdout)){
			chomp($stdout);
			print ($stdout."\n");
		} elsif(defined($stderr)){
			print ("ERR:\n".$stderr."\n");
		}
	} else{
		print "Failed to connect with server $host. Err: $@";
	}
}

sub usage{
print shift."\n";
print <<EOF;
usage: distributed-cmd.pl [OPTIONS]
Runs a command by ssh on a list of servers given. Before run the command on the remote server a check command is executed, if returns 0 then the command will be run on the server.
Arguments:
	--hosts		: List of hosts to run the command
	--check		: Command line to decide if the server should or not run the command.
	--command	: Command line to run.
	--user		: user to connect with the servers. If not defined, by default is root.
	--help		: print this menu help
Example:
	./distributed-cmd.pl --hosts srv1 srv2 --check "pidof apache2" --command "sudo /usr/sbin/service apache2 restart" --user root
EOF
        exit 0;
}
