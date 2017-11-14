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
git clone -b 8.0 https://github.com/OCA/l10n-italy.git
mv l10n-italy/l10n_it_* ./addons
rm -rf l10n-italy

rm -rf l10n-italy-supplemental
git clone -b 8.0 https://github.com/zeroincombenze/l10n-italy-supplemental.git
mv l10n-italy-supplemental/l10n_it_* ./addons
rm -rf l10n-italy-supplemental

python run_before_image_creation.py