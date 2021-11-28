sudo route add -net 172.30.0.0 -netmask 255.255.252.0 10.8.0.1
sudo route add -net 172.30.4.0 -netmask 255.255.252.0 10.8.0.1
netstat -nr | grep 10.8.