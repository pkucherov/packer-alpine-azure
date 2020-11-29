# Community package required for shadow
echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories

apk update && apk upgrade

# Pre-reqs for WALinuxAgent
apk add openssl sudo bash shadow parted iptables sfdisk openntpd
apk add python3 py3-setuptools py-pip
python3 -m ensurepip --default-pip
python3 -m pip install --upgrade pip setuptools wheel
pip install distro

# Install WALinuxAgent
wget https://github.com/Azure/WALinuxAgent/archive/v2.2.49.2.tar.gz && \
tar xvzf v2.2.49.2.tar.gz && \
cd WALinuxAgent-2.2.49.2 && \
python3 setup.py install --register-service && \
cd .. && \
rm -rf WALinuxAgent-2.2.49.2 v2.2.49.2.tar.gz

# Update boot params
sed -i 's/^default_kernel_opts="[^"]*/\0 console=ttyS0 earlyprintk=ttyS0 rootdelay=300/' /etc/update-extlinux.conf
update-extlinux

# sshd configuration
sed -i 's/^#ClientAliveInterval 0/ClientAliveInterval 180/' /etc/ssh/sshd_config

# Start waagent at boot
cat > /etc/init.d/waagent <<EOF
#!/sbin/openrc-run                                                                 

export PATH=/usr/local/sbin:$PATH

start() {                                                                          
        ebegin "Starting waagent"                                                  
        start-stop-daemon --start --exec /usr/sbin/waagent --name waagent -- -start
        eend $? "Failed to start waagent"                                          
}
EOF

chmod +x /etc/init.d/waagent
rc-update add waagent default

# Workaround for default password
# Basically, useradd on Alpine locks the account by default if no password
# was given, and the user can't login, even via ssh public keys. The useradd.sh script
# changes the default password to a non-valid but non-locking string.
# The useradd.sh script is installed in /usr/local/sbin, which takes precedence
# by default over /usr/sbin where the real useradd command lives.
mkdir -p /usr/local/sbin
mv /tmp/useradd.sh /usr/local/sbin/useradd
chmod +x /usr/local/sbin/useradd
