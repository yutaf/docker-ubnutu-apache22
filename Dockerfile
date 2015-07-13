FROM ubuntu:14.04
MAINTAINER yutaf <fujishiro@amaneku.co.jp>

RUN apt-get update
RUN apt-get install -y \
# binaries for login shell usage (not essential)
  man \
  curl \
# Apache \
  make \
  gcc \
  zlib1g-dev \
  libssl-dev \
  libpcre3-dev \
  git \
# supervisor
  supervisor

# COPY src
COPY src /usr/local/src/

#
# Apache
#

RUN cd /usr/local/src && \
  tar xzvf httpd-2.2.29.tar.gz && \
  cd httpd-2.2.29 && \
    ./configure \
      --prefix=/opt/apache2.2.29 \
      --enable-mods-shared=all \
      --enable-proxy \
      --enable-ssl \
      --with-ssl \
      --with-mpm=prefork \
      --with-pcre

# install
RUN cd /usr/local/src/httpd-2.2.29 && \
  make && make install

#
# Edit config files
#

# Apache config
RUN sed -i "s/^Listen 80/#&/" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s/^DocumentRoot/#&/" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "/^<Directory/,/^<\/Directory/s/^/#/" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;ScriptAlias /cgi-bin;#&;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;#\(Include conf/extra/httpd-mpm.conf\);\1;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;#\(Include conf/extra/httpd-default.conf\);\1;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s/\(ServerTokens \)Full/\1Prod/" /opt/apache2.2.29/conf/extra/httpd-default.conf && \
  echo "Include /srv/apache/apache.conf" >> /opt/apache2.2.29/conf/httpd.conf && \
# Change User & Group
  useradd --system --shell /usr/sbin/nologin --user-group --home /dev/null apache; \
  sed -i "s;^\(User \)daemon$;\1apache;" /opt/apache2.2.29/conf/httpd.conf && \
  sed -i "s;^\(Group \)daemon$;\1apache;" /opt/apache2.2.29/conf/httpd.conf

COPY templates/apache.conf /srv/apache/apache.conf
RUN echo 'CustomLog "|/opt/apache2.2.29/bin/rotatelogs /srv/www/logs/access/access.%Y%m%d.log 86400 540" combined' >> /srv/apache/apache.conf && \
  echo 'ErrorLog "|/opt/apache2.2.29/bin/rotatelogs /srv/www/logs/error/error.%Y%m%d.log 86400 540"' >> /srv/apache/apache.conf
#  "mkdir {a,b}" does not work in Ubuntu's /bin/sh, And "RUN <command>" uses "/bin/sh -c".
# Use "RUN ["executable", "param1", "param2"]" instead of "RUN <command>"
RUN ["/bin/bash", "-c", "mkdir -m 777 -p /srv/www/logs/{access,error,app}"]

# make Apache document root
COPY www/htdocs/ /srv/www/htdocs/

# supervisor
COPY templates/supervisord.conf /etc/supervisor/conf.d/
RUN echo '[program:apache2]' >> /etc/supervisor/conf.d/supervisord.conf && \
  echo 'command=/opt/apache2.2.29/bin/httpd -DFOREGROUND' >> /etc/supervisor/conf.d/supervisord.conf

# set TERM
RUN echo export TERM=xterm-256color >> /root/.bashrc && \
# set timezone
  ln -sf /usr/share/zoneinfo/Japan /etc/localtime

# Delete logs except dot files
RUN echo '00 5 1,15 * * find /srv/www/logs -regex ".*/\.[^/]*$" -prune -o -type f -mtime +15 -print -exec rm -f {} \;' > /root/crontab && \
  crontab /root/crontab

# Set up script for running container
COPY scripts/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

EXPOSE 80
CMD ["/usr/local/bin/run.sh"]
