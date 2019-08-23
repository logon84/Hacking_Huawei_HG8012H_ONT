#/bin/sh

#open dropbear port
iptables -I INPUT -p tcp --dport 2222 -j ACCEPT

#run ssh server
dropbear -r /bin/hostkey -p 2222
