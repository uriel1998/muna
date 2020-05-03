#!/bin/bash

source "$SCRIPT_DIR/unredirector.sh"
APPDIR="/home/steven/apps/ArchiveBox-Docker"
RAWDIR="$APPDIR/rawdata"
DATADIR="$APPDIR/data"

#this should be a variable, I think.


if [ ! -d "$RAWDIR" ]; then
    mkdir "$RAWDIR"
fi

wget https://shaarli.stevesaus.me/?do=atom -O- | grep -e "<link href" | awk -F '"' '{print $2}' > $RAWDIR/shaarli.txt

wget https://bag.faithcollapsing.com/ssaus/kJ8VHqEOOfzkp7/unread.xml -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' > $RAWDIR/data/wallabag.txt

wget https://ideatrash.net/feed -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' > $RAWDIR/ideatrash.txt

wget https://ideatrash.net/sitemap-1.xml -O- | sed -e 's:<url>:\n<url>:g' | sed -e 's:.*<loc>\(.*\)</loc>.*:\1:g' > $RAWDIR/full_ideatrash.txt

wget "https://rss.stevesaus.me/public.php?op=rss&id=-2&view-mode=all_articles&key=9u5pdo5e07852179fb9" -O- | grep -e "<link href" | awk -F '"' '{print $2}' > $RAWDIR/ttrss.txt




sudo docker-compose exec archivebox /bin/archive data/ideatrash.txt
sudo docker-compose exec archivebox /bin/archive data/shaarli.txt
sudo docker-compose exec archivebox /bin/archive data/wallabag.txt
sudo docker-compose exec archivebox /bin/archive data/ttrss.txt
sudo docker-compose exec archivebox /bin/archive data/full_ideatrash.txt



