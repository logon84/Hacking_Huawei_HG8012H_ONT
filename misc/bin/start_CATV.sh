#/bin/sh

#wait to boot
sleep 80

#set catv output on
{ sleep 1; echo ""; sleep 3; echo "root"; sleep 3; echo "admin"; sleep 3; echo "su"; sleep 3; echo "set rf switch on"; sleep 3; echo "quit"; sleep 3; echo "quit"; } | console.sh
