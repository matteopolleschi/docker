FROM ubuntu:16.04
MAINTAINER vertuzz <alexavd@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y python-pip postgresql-client \
    nginx fail2ban software-properties-common supervisor logrotate cron \
    && add-apt-repository ppa:certbot/certbot \
    && apt-get update && apt-get install python-certbot-nginx -y

COPY front_hosts.conf /etc/nginx/sites-available/front_hosts.conf
COPY front_nginx.conf /etc/nginx/front_nginx.conf
COPY front_supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY jail.local /etc/fail2ban/jail.local
COPY nginx-req-limit.conf /etc/fail2ban/filter.d/nginx-req-limit.conf
COPY logrotate /etc/logrotate.d/nginx
COPY crontab /etc/cron.d/app-cron
COPY backupper.py /root/backupper.py
COPY env.sh /root/env.sh

RUN pip install --upgrade pip

RUN pip install boto3==1.4.7

RUN mkdir -p /var/log/nginx/app /var/log/supervisor \
    && rm /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/front_hosts.conf /etc/nginx/sites-enabled/front_hosts.conf \
    && rm /etc/nginx/nginx.conf && mv /etc/nginx/front_nginx.conf /etc/nginx/nginx.conf  \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && chown -R www-data:www-data /var/log \
    && chmod +x /root/env.sh \
    && touch /var/log/auth.log && chmod 0644 /etc/cron.d/app-cron \
    && touch /var/log/cron.log

CMD ["/usr/bin/supervisord"]
