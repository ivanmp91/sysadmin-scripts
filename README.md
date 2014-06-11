sysadmin-scripts
================

This is a public repository with some useful scripts I've developed. You're free to fork the repository, modify and use it for your personal use. I'll keep updated the repository adding and modifying scripts under my needs, but improvements and proposals are welcome as well.

Thanks for visit the repository and hope the scripts will be useful for you.

Author: Ivan Mora Perez - ivan@opentodo.net

List of Scripts
================
*   [__distributed-cmd__][1]

	Runs a command by ssh on a list of servers given. Before run the command on the remote server a check command is executed, if returns 0 then the command will be run on the server. Example:

	./distributed-cmd.pl --hosts srv1 srv2 --check "pidof apache2" --command "sudo /usr/sbin/service apache2 restart" --user ivan
	
[1]: distributed-cmd.pl


