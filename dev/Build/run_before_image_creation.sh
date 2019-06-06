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

rm -rf l10n-italy
git clone -b 12.0 https://github.com/OCA/l10n-italy.git
# mv l10n-italy/l* ./addons
#mv l10n-italy/l10n_it_* ./addons
echo "Merge https://github.com/OCA/l10n-italy.git to addonns/"
rsync -a l10n-italy/l10n_it_ ./addons
rm -rf l10n-italy

rm -rf partner-contact
git clone -b 12.0 https://github.com/OCA/partner-contact.git
#mv partner-contact/* ./addons
echo "Merge https://github.com/OCA/partner-contact.git to addonns/"
rsync -a partner-contact/ ./addons
rm -rf partner-contact

rm -rf account-financial-tools
git clone -b 12.0 https://github.com/OCA/account-financial-tools.git
#mv account-financial-tools/* ./addons
echo "Merge https://github.com/OCA/account-financial-tools.git to addonns/"
rsync -a account-financial-tools/ ./addons
rm -rf account-financial-tools

rm -rf account-financial-reporting
git clone -b 12.0 https://github.com/OCA/account-financial-reporting.git
#mv account-financial-reporting/* ./addons
echo "Merge https://github.com/OCA/account-financial-reporting.git to addonns/"
rsync -a account-financial-reporting/ ./addons
rm -rf account-financial-reporting

rm -rf server-ux
git clone -b 12.0 https://github.com/OCA/server-ux.git
#mv server-ux/* ./addons
echo "Merge https://github.com/OCA/server-ux.git to addonns/"
rsync -a server-ux/ ./addons
rm -rf server-ux

rm -rf crm
git clone -b 12.0 https://github.com/OCA/crm.git
#mv crm/* ./addons
echo "Merge https://github.com/OCA/crm.git to addonns/"
rsync -a crm/ ./addons
rm -rf crm

rm -rf odoo_publishers
git clone -b 12.0 https://github.com/matteopolleschi/odoo_publishers.git
#mv odoo_publishers ./addons
echo "Merge https://github.com/matteopolleschi/odoo_publishers.git to addonns/"
rsync -a odoo_publishers/ ./addons
rm -rf odoo_publishers

#rm -rf l10n-italy-supplemental
#git clone -b 11.0 https://github.com/zeroincombenze/l10n-italy-supplemental.git
# mv l10n-italy-supplemental/l10n_it_* ./addons
#mv l10n-italy-supplemental/* ./addons
#rm -rf l10n-italy-supplemental

#rm -rf stock-logistics-workflow
#git clone -b 11.0 https://github.com/OCA/stock-logistics-workflow.git
#mv stock-logistics-workflow/stock* ./addons
#rm -rf stock-logistics-workflow

# rm -rf l10n-italy
# git clone -b 11.0-mig-l10n_it_ddt https://github.com/dcorio/l10n-italy.git
# mv l10n-italy/l10n_it_ddt ./addons
# rm -rf l10n-italy

#rm -rf odoo_imppn
#git clone -b 11.0 https://github.com/matteopolleschi/odoo_imppn.git
#mv odoo_imppn ./addons
#rm -rf odoo_imppn


python run_before_image_creation.py