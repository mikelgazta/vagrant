DNSIP=$1
apt-get update
apt-get install -y bind9 bind9utils bind9-doc

cat <<EOF >/etc/bind/named.conf.options
acl "allowed" {
    192.168.33.0/24;
};

options {
    directory "/var/cache/bind";
    dnssec-validation auto;

    listen-on-v6 { any; };
    forwarders { 1.1.1.1;  1.0.0.1;  };
};
EOF

cat <<EOF >/etc/bind/named.conf.local
zone "ZONA.COM" {
        type master;
        file "/var/lib/bind/ZONA.COM";
        };
zone "33.168.192.in-addr.arpa" {
        type master;
        file "/var/lib/bind/33.168.192.rev";
        };
EOF

cat <<EOF >/var/lib/bind/ZONA.COM
\$TTL 3600
ZONA.COM.     IN      SOA     ns.ZONA.COM. santi.ZONA.COM. (
                3            ; serial
                7200         ; refresh after 2 hours
                3600         ; retry after 1 hour
                604800       ; expire after 1 week
                86400 )      ; minimum TTL of 1 day

ZONA.COM.          IN      NS      ns.ZONA.COM.
ns.ZONA.COM.       IN      A       $DNSIP
nginx IN  A   192.168.33.11
apache1 IN  A 192.168.33.12
apache2 IN  A   192.168.33.13
gnome   IN  A   192.168.33.14
; aqui pones los hosts
EOF

cat <<EOF >/var/lib/bind/33.168.192.rev
\$ttl 3600
33.168.192.in-addr.arpa.  IN      SOA     ns.ZONA.COM. santi.ZONA.COM. (
                3            ; serial
                7200         ; refresh after 2 hours
                3600         ; retry after 1 hour
                604800       ; expire after 1 week
                86400 )      ; minimum TTL of 1 day

@   IN      NS      ns.ZONA.COM.
10  IN      NS      ns.ZONA.COM.
11  IN      PTR      nginx
12  IN  PTR     apache1
13  IN  PTR     apache2
14  IN  PTR     gnome
; aqui pones los hosts inversos
EOF

cp /etc/resolv.conf{,.bak}
cat <<EOF >/etc/resolv.conf
nameserver 192.168.33.10
domain ZONA.COM.
EOF

named-checkconf
named-checkconf /etc/bind/named.conf.options
named-checkzone ZONA.COM /var/lib/bind/ZONA.COM
named-checkzone 33.168.192.in-addr.arpa /var/lib/bind/33.168.192.rev
sudo systemctl restart bind9