#!/bin/sh

set -euxo pipefail

[ -z ${VPN_CONN_NAME} ] && exit 1
[ -z ${VPN_CLIENT_IPV4} ] && exit 1
[ -z ${VPN_CLIENT_SUBNET} ] && exit 1
[ -z ${VPN_CLIENT_GW} ] && exit 1
[ -z ${VPN_SERVER_IPV4} ] && exit 1
[ -z ${VPN_SERVER_SUBNET} ] && exit 1
[ -z ${VPN_PSK} ] && exit 1
VPN_IF=${VPN_IF:-dummy0}

IKE_ALG=${IKE_ALG:-aes256-sha2_512;dh20}
P2=${P2:-esp}
P2_ALG=${P2_ALG:-aes256-sha2_512;dh20}

cat > /etc/ipsec.d/vpn.conf <<EOF
conn ${VPN_CONN_NAME}
    # general
    type=tunnel
    left=${VPN_CLIENT_IPV4}
    leftsubnet=${VPN_CLIENT_SUBNET}
    leftupdown=%disabled
    right=${VPN_SERVER_IPV4}
    rightsubnet=${VPN_SERVER_SUBNET}

    # keying
    auto=start
    authby=secret

    ike=${IKE_ALG}
    phase2=${P2}
    phase2alg=${P2_ALG}

    dpddelay=15
    dpdtimeout=30
    dpdaction=clear
    ikev2=yes
    ikelifetime=86400s
    keylife=1h
    rekey=yes
EOF

cat > /etc/ipsec.d/vpn.secrets <<EOF
: PSK "${VPN_PSK}"
EOF

VPN_CLIENT_MASK=$(echo ${VPN_CLIENT_SUBNET} | cut -d '/' -f2)

ip link add ${VPN_IF} type dummy
ip link set ${VPN_IF} up
ip address add ${VPN_CLIENT_GW}/${VPN_CLIENT_MASK} dev ${VPN_IF}
ip route add ${VPN_SERVER_SUBNET} dev ${VPN_IF} src ${VPN_CLIENT_GW}

# startup ipsec tunnel
ipsec initnss
ipsec pluto --stderrlog --config /etc/ipsec.conf --nofork
