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
git clone -b 8.0 https://github.com/OCA/partner-contact.git --depth 1
mv partner-contact/* ./addons
rm -rf partner-contact

rm -rf l10n-italy
git clone -b 8.0 https://github.com/OCA/l10n-italy.git --depth 1
# mv l10n-italy/l* ./addons
mv l10n-italy/l10n_it_* ./addons
mv l10n-italy/account_invoice_entry_date ./addons
rm -rf l10n-italy

rm -rf l10n-italy-supplemental
git clone -b 8.0 https://github.com/zeroincombenze/l10n-italy-supplemental.git --depth 1
# mv l10n-italy-supplemental/l10n_it_* ./addons
mv l10n-italy-supplemental/* ./addons
rm -rf l10n-italy-supplemental

rm -rf stock-logistics-workflow
git clone -b 8.0 https://github.com/OCA/stock-logistics-workflow.git --depth 1
mv stock-logistics-workflow/stock* ./addons
rm -rf stock-logistics-workflow

rm -rf odoo_imppn
git clone https://github.com/matteopolleschi/odoo_imppn.git --depth 1
mv odoo_imppn ./addons
rm -rf odoo_imppn

rm -rf odoo_publishers
git clone https://github.com/matteopolleschi/odoo_publishers.git --depth 1
mv odoo_publishers ./addons
rm -rf odoo_publishers

rm -rf odoo_import_upwork
git clone https://github.com/matteopolleschi/odoo_import_upwork.git --depth 1
mv odoo_import_upwork ./addons
rm -rf odoo_import_upwork

rm -rf l10n-italy
git clone https://github.com/Odoo-Italia-Associazione/l10n-italy.git -b 8.0 --depth 1
mv l10-italy/l10n_it_einvoice_base ./addons
rm -rf l10-italy

python run_before_image_creation.py
