#!/bin/bash

# checking if this PC has a swap
if free | awk '/^Swap:/ {exit !$2}'; then
    echo "Have swap"
else
    echo "No swap, creating one"
    fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# how 2 remove swap file:
# swapoff /swapfile
# rm /swapfile

rm -rf addons
rm -rf l10n_it*
mkdir addons

rm -rf partner-contact
git clone -b 11.0 https://github.com/OCA/partner-contact.git
mv partner-contact/* ./addons
rm -rf partner-contact

rm -rf l10n-italy
git clone -b 11.0 https://github.com/OCA/l10n-italy.git
# mv l10n-italy/l* ./addons
mv l10n-italy/l10n_it_* ./addons
rm -rf l10n-italy

rm -rf l10n-italy-supplemental
git clone -b 11.0 https://github.com/zeroincombenze/l10n-italy-supplemental.git
# mv l10n-italy-supplemental/l10n_it_* ./addons
mv l10n-italy-supplemental/* ./addons
rm -rf l10n-italy-supplemental

rm -rf stock-logistics-workflow
git clone -b 11.0 https://github.com/OCA/stock-logistics-workflow.git
mv stock-logistics-workflow/stock* ./addons
rm -rf stock-logistics-workflow

# rm -rf l10n-italy
# git clone -b 11.0-mig-l10n_it_ddt https://github.com/dcorio/l10n-italy.git
# mv l10n-italy/l10n_it_ddt ./addons
# rm -rf l10n-italy

rm -rf odoo_imppn
git clone -b 11.0 https://github.com/matteopolleschi/odoo_imppn.git
mv odoo_imppn ./addons
rm -rf odoo_imppn

rm -rf odoo_publishers
git clone https://github.com/matteopolleschi/odoo_publishers.git
mv odoo_publishers ./addons
rm -rf odoo_publishers


python run_before_image_creation.py
