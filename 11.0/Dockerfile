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
            python3-pyldap \
            python3-qrcode \
            python3-setuptools \
            python3-vobject \
            python3-renderpm \
            libssl1.0-dev \
            xz-utils \
            python3-watchdog \
        && curl -o wkhtmltox.deb -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
        && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb\
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install Git 
RUN apt-get update && apt-get install -y git  

# Install Odoo
ENV ODOO_VERSION 11.0
ENV ODOO_RELEASE 20181116
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo '7bcc840529712e19f2215bac77920ae75a81d5d5 odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Correct setting to see assigned leads
# COPY ./crm_lead_view.xml /usr/lib/python3/dist-packages/odoo/addons/crm

# Copy entrypoint script and Odoo configuration file
RUN pip3 install wheel \
    && pip3 install num2words xlwt unidecode
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
