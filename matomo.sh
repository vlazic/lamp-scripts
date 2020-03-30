#!/bin/bash

# download and unzip latest matomo
wget https://builds.matomo.org/matomo-latest.zip
unzip matomo-latest.zip -d .

# remove files we dont need and move everything from matomo/ folder
# into the current dir
rm -fr How\ to\ install\ Matomo.html matomo-latest.zip
mv matomo/* .
mv matomo/.* .
rm -fr matomo

# get latest DBIP Geo IP file
CURRENT_MONTH=$(date +%Y-%m)
PREV_MONTH=$(date --date="$(date +%Y-%m-15) -1 month" +'%Y-%m')
wget "https://download.db-ip.com/free/dbip-city-lite-${CURRENT_MONTH}.mmdb.gz" -O DBIP-City.mmdb.gz ||
    wget "https://download.db-ip.com/free/dbip-city-lite-${PREV_MONTH}.mmdb.gz" -O DBIP-City.mmdb.gz
gunzip DBIP-City.mmdb.gz
mv DBIP-City.mmdb misc/

echo "To finish installation of DBIP GeoIP you need to check 'DBIP / GeoIP 2 (Php)' on Geolocation section of Matomo Administration page."
