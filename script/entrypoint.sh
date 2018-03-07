#!/bin/sh
echo "start nginx"

#set TZ
cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
echo ${TZ} > /etc/timezone && \

mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/ssl

#copy /etc/nginx/service*.conf if any of servcie*.conf mounted
if [ -f /etc/nginx/service*.conf ]; then
    cp -fv /etc/nginx/service*.conf /etc/nginx/conf.d/
fi

#generate dhparams.pem
if [ ! -f /etc/nginx/ssl/dhparams.pem ]; then
    echo "make dhparams"
    cd /etc/nginx/ssl
    openssl dhparam -out dhparams.pem 2048
    chmod 600 dhparams.pem
fi

#disable service configurations and let it run without SSL
sed -i "s|include /etc/nginx/conf.d/\*.conf;|# include /etc/nginx/conf.d/\*.conf;|g" /etc/nginx/nginx.conf

(
 sleep 5 #give nginx time to start
 echo "start letsencrypt updater"
 while :
 do
	echo "trying to update letsencrypt ..."
    /le.sh
    rm -f /etc/nginx/conf.d/default.conf 2>/dev/null #remove default config, conflicting on 80
    sed -i "s|# include /etc/nginx/conf.d/\*.conf;|include /etc/nginx/conf.d/\*.conf;|g" /etc/nginx/nginx.conf # enable
    echo "reload nginx with ssl"
    nginx -s reload
    sleep 60d
 done
) &


nginx -g "daemon off;"
