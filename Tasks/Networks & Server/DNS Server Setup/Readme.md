DNS Server Setup
•	Set up a local DNS server using Bind.
•	Use your own machine as the nameserver.
•	Test DNS queries with `dig` and `nslookup` for both authoritative and non-authoritative answers.
•	Use host01.cloudethix.com as your domain name.
•	Understand different RR records.
•	Configure MX Record in DNS Zone file. 
Note:- Make sure to update resolv.conf file to update your DNS name. 
Ans:-
Step 1: Installing Bind DNS on RHEL 8
1. To install bind and its utilities on your server, run the following cdnf command.
# dnf install bind bind-utils
2. Next, start the DNS service for now, then enable it to auto-start at system boot and check if it is up and running using the systemctl commands.
# systemctl start named
# systemctl enable named
# systemctl status named
 
Step 2: Configuring BIND DNS on RHEL 8
3. To configure Bind DNS server, first you need to take a backup of the original configuration file /etc/named.conf using following cp command.
# cp /etc/named.conf /etc/named.conf.orig
4. Now open /etc/named.conf configuration file for editing using your favorite command line text editor as follows.
5. Next, look for the allow-query parameter and set its value to your network, which means that only hosts on your local network can query the DNS server.
options {
        listen-on port 53 { 127.0.0.1; 10.10.56.211; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { localhost; 10.10.56.211; 10.10.57.49; };
        forwarders { 8.8.8.8; 1.1.1.1;};
Step 3: Creating the Forward and Reverse DNS Zones
A Forward Zone is where the hostname (or FQDN) to IP address relations are stored; it returns an IP address using the hostname.
//forward zone
zone "host01.cloudethix.com" IN {
        type master;
        file "host01.cloudethix.com.zone";
};

//backward zone
zone "56.10.10.in-addr.arpa" IN {
        type master;
        file "host01.cloudethix.com.rev";
};
Step 4: Creating Forward DNS Zone File
7. First, create a Forward zone file under the /var/named directory.
# nano /var/named/host01.cloudethix.com.zone
Add the following configuration in it.
$TTL 86400
@ IN SOA ns1.host01.cloudethix.com. admin.host01.cloudethix.com. (
        2025100201; Serial
        3600      ; Refresh
        1800      ; Retry
        1209600   ; Expire
        86400 )   ; Minimum TTL
        IN NS ns1.host01.cloudethix.com.
        IN NS ns2.host01.cloudethix.com.

@       IN A 10.10.56.211
ns1     IN A 10.10.56.211
ns2     IN A 10.10.56.211

; MX Record
@       IN  MX 10 mail.host01.cloudethix.com.
mail    IN  A       10.10.56.212
Step 5: Creating Reverse DNS Zone File
8. Similary, create a Reverse zone file under the /var/named directory.
# nano /var/named/host01.cloudethix.com.rev
Then add the following lines in it. Here, the PTR is the opposite of A record used to map an IP address to a hostname.
$TTL 86400
@       IN SOA ns1.host01.cloudethix.com. admin.web01.cloudethix.com (
                2025021101      ; Serial
                3600            ; Refresh
                1800            ; Retry
                1209600         ; Expire
                86400 )         ; Minimum TTL

        IN NS ns1.host01.cloudethix.com.
        IN NS ns1.host01.cloudethix.com.

104     IN PTR host01.cloudethix.com.
105     IN  PTR     mail.host01.cloudethix.com.
11      IN PTR ns1.host01.cloudethix.com.
12      IN PTR ns2.host01.cloudethix.com.
9. Set the correct ownership permissions on the zone files as follows.
# chown :named /var/named/tecmint.lan.db
# chown :named /var/named/tecmint.lan.rev
10. Finally, check the DNS configuration and the zone files has the correct syntax after making the above changes, using the named-checkconf utility (no out means no error):
# named-checkconf
# named-checkzone host01.cloudethix.com /var/named/host01.cloudethix.com.zone
 # named-checkzone 10.10.57.104 /var/named/host01.cloudethix.com.rev
 
11. Once you have performed all the necessary configuration, you need to restart the DNS service for the recent changes to take effect.
# systemctl restart named
12. Next, before any clients can access the DNS service configurations on the server, you need to add the DNS service in the system firewall config and reload the firewall settings using the firewall-cmd utility, as follows:
# firewall-cmd --permanent --zone=public --add-service=dns 
# firewall-cmd --reload
 
Step 6: Testing DNS Service From a Client
13. In this section, we will show how to test the DNS service from a client side. Log into the client machine, configure it to use the above DNS server. On a Linux system, open the file /etc/resolve.conf using your favorite text editor.
# nano /etc/resolve.conf 
Add the following entry in it, which tells the resolver to use the specified nameserver.
nameserver  10.10.56.211
14. Add the DNS servers IP 10.10.56.211 as resolver to the client machine network interface configuration file /etc/sysconfig/network-scripts/ifcfg-enp0s3.
15. Then use the nslookup utility to query the IP using the hostname and vise versa,
