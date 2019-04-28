#!/usr/bin/bash

##
# さくらのVPS で カスタムスクリプト として動作させるためのスクリプトです
# このスクリプトは、さくらインターネットさんが公開されているスタートアップスクリプトを
# ベースに作成を行っております。感謝！
# https://github.com/sakura-internet/cloud-startupscripts
# 
# カスタムスクリプトについては さくらインターネットさん で調査やQAなどの対応は”していません”
# 自己責任での利用をお願いします 
#
# 以下を置換して利用してください
#  @@@@@your domain name@@@@@ -----> SSL証明書を取得するドメイン名 
#  @@@@@youre email addres@@@@@ -----> let's encryptの通知を受け取るメールアドレス
#  @@@@@Node-Red flow editer login id@@@@@ -----> Node-RED フローエディターのログインID（５文字以上）
#  @@@@@Node-Red flow editer login password@@@@@ -----> Node-RED フローエディターのパスワード（8文字以上）
#
##

## start ----- ScriptName: CentOS_LetsEncrypt

set -x

# Environment Variables
OS_MAJOR_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release)
ARCH=$(arch)
DOMAIN="@@@@@your domain name@@@@@"
MAIL_ADDRESS="@@@@@youre email addres@@@@@"

# Install nginx
cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/${OS_MAJOR_VERSION}/${ARCH}/
gpgcheck=0
enabled=1
EOF

yum clean all
yum install nginx -y

# Install cert-bot
CPATH=/usr/local/certbot
git clone https://github.com/certbot/certbot ${CPATH}

# Configure firewall
firewall-cmd --permanent --add-port={80,443}/tcp
firewall-cmd --reload

# Configure nginx
LD=/etc/letsencrypt/live/${DOMAIN}
CERT=${LD}/fullchain.pem
PKEY=${LD}/privkey.pem

cat << _EOF_ > https.conf
map \$http_upgrade \$connection_upgrade {
	default upgrade;
	''      close;
}
server {
	listen 443 ssl http2;
	server_name ${DOMAIN};

#       access_log  /var/log/nginx/websocket.access.log  main;

        location / {
#                root   /usr/share/nginx/html;
#                index  index.html index.htm;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto \$scheme;
                proxy_set_header Host $http_host;

                proxy_pass http://127.0.0.1:1880;
                proxy_redirect off;

                # socket.io support
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection "upgrade";
        }

	ssl_protocols TLSv1.2;
	ssl_ciphers EECDH+AESGCM:EECDH+AES;
	ssl_ecdh_curve prime256v1;
	ssl_prefer_server_ciphers on;
	ssl_session_cache shared:SSL:10m;

	ssl_certificate ${CERT};
	ssl_certificate_key ${PKEY};

	error_page   500 502 503 504  /50x.html;
	location = /50x.html {
		root   /usr/share/nginx/html;
	}
}
_EOF_

systemctl enable nginx

# Configure Let's Encrypt
WROOT=/usr/share/nginx/html
systemctl start nginx
${CPATH}/certbot-auto -n certonly --webroot -w ${WROOT} -d ${DOMAIN} -m ${MAIL_ADDRESS} --agree-tos --server https://acme-v02.api.letsencrypt.org/directory

if [ ! -f ${CERT} ]
then
	echo "証明書の取得に失敗しました"
	exit 1
fi

## Configure SSL Certificate Renewal
mv https.conf /etc/nginx/conf.d/
R=${RANDOM}
echo "$((R%60)) $((R%24)) * * $((R%7)) root ${CPATH}/certbot-auto renew --webroot -w ${WROOT} --post-hook 'systemctl reload nginx'" > /etc/cron.d/certbot-auto

systemctl restart nginx

# exit 0
## end ----- ScriptName: CentOS_LetsEncrypt

## start ----- ScriptName: CentOS_NodeRed

UI_PORT=1880
UI_NODERED_ID=@@@@@Node-Red flow editer login id@@@@@
UI_NODERED_PASSWORD=@@@@@Node-Red flow editer login password@@@@@

set -x

export HOME=/root/ && export PM2_HOME="/root/.pm2"

# yum update
yum -y update

# Add repo
curl -sL https://rpm.nodesource.com/setup_8.x | bash -

# Setup Node.js/Node-Red
yum install -y nodejs
npm install -g --unsafe-perm node-red

# Auto start-up Node-Red
npm install -g pm2
pm2 start /usr/bin/node-red -- -u root -p $UI_PORT
pm2 save
pm2 startup systemd -u root

# firewall
#firewall-cmd --add-port=$UI_PORT/tcp --permanent
#firewall-cmd --reload

if [ -n "${UI_NODERED_ID}" ] && [ -n "${UI_NODERED_PASSWORD}" ] ; then

  npm install bcryptjs
  UI_NODERED_PASSWORD_CRYPT=`node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 8));" "${UI_NODERED_PASSWORD}"`

  sed -i -e "s/\/\/adminAuth:/adminAuth:{\n\
        type: \"credentials\",\n\
        users: [{\n\
            username: \"VPS_NODERED_ID\",\n\
            password: \"VPS_NODERED_PASSWORD\",\n\
            permissions: \"*\"\n\
        }]\n\
    },\n\
    \/\/adminAuth:/" /root/settings.js

  sed -i -e "s*VPS_NODERED_ID*${UI_NODERED_ID}*" /root/settings.js
  sed -i -e "s*VPS_NODERED_PASSWORD*${UI_NODERED_PASSWORD_CRYPT}*" /root/settings.js

  ### restart
  pm2 restart node-red

fi

#reboot
## end ----- ScriptName: CentOS_NodeRed

## start ----- ScriptName: change mariaDb to MySQL
# remove mariadb
yum -y remove mariadb-libs
rm -rf /var/lib/mysql

# install mysql
# @see https://dev.mysql.com/downloads/repo/yum/
#rpm -ivh http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
rpm -ivh http://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm
yum -y install mysql-community-server

# Auto start-up MySQL
systemctl start mysqld.service
systemctl enable mysqld.service

# @note MySQL initial login information
# sudo cat /var/log/mysqld.log | grep password
# "mysql_secure_installation" after reboot

# add node-red plugin
npm install --prefix /node-red-node-mysql
pm2 restart node-red

## end ----- ScriptName: change mariaDb to MySQL

## start ----- ScriptName: install memcached
# @see https://yomon.hatenablog.com/entry/2016/02/16/195809 を参考にさせていただきました

# install mysql
yum -y install memcached

# Auto start-up memcached
systemctl start memcached.service
systemctl enable memcached.service

# @note memcached setting param
# cat /etc/sysconfig/memcached

# add node-red plugin
npm install --production node-red-contrib-cache
pm2 restart node-red

## end ----- ScriptName: install memcached

## start ----- ScriptName: CentOS_yum-update

set -x

yum clean all
yum -y update
reboot

## end ----- ScriptName: CentOS_yum-update
