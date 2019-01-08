FROM debian:stretch
MAINTAINER Odoo S.A. <info@odoo.com>

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            python3-pyldap \
            python3-qrcode \
            python3-vobject \
            python3-watchdog \
            libssl1.0-dev \
            xz-utils \
        && curl -o wkhtmltox.tar.xz -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
        && echo '3f923f425d345940089e44c1466f6408b9619562 wkhtmltox.tar.xz' | sha1sum -c - \
        && tar xvf wkhtmltox.tar.xz \
        && cp wkhtmltox/lib/* /usr/local/lib/ \
        && cp wkhtmltox/bin/* /usr/local/bin/ \
        && cp -r wkhtmltox/share/man/man1 /usr/local/share/man/

# Install Git 
RUN apt-get update && apt-get install -y git  


# Install Odoo
ENV ODOO_VERSION 12.0
ENV ODOO_RELEASE 20181006
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb
        
# Correct setting to see assigned leads
# COPY ./crm_lead_view.xml /usr/lib/python3/dist-packages/odoo/addons/crm

# Copy entrypoint script and Odoo configuration file
RUN pip3 install wheel \
    && pip3 install num2words xlwt
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Install python library pyIMPPN
RUN python3 -m pip install --user --upgrade setuptools wheel twine \
    && git clone -b python3 https://github.com/matteopolleschi/pyIMPPN.git pyIMPPN-master \
    && cd pyIMPPN-master \
    && python3 setup.py install \
    && cd -

# Install Italian Modules dependencies
RUN pip3 install psycogreen==1.0 \
    && pip3 install pyxb==1.2.4 \
    && pip3 install unicodecsv \
    && pip3 install codicefiscale==0.9 \
    && pip3 install phonenumbers

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Add Italian Modules
COPY ./addons /mnt/extra-addons/
RUN ls -la /mnt/extra-addons/*

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]