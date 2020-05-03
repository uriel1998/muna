#!/bin/bash

source "$SCRIPT_DIR/unredirector.sh"

#this should be a variable, I think.
cd /home/steven/apps/ArchiveBox-Docker

wget https://shaarli.stevesaus.me/?do=atom -O- | grep -e "<link href" | awk -F '"' '{print $2}' > /home/steven/apps/ArchiveBox-Docker/data/shaarli.txt

wget https://bag.faithcollapsing.com/ssaus/kJ8VHqEOOfzkp7/unread.xml -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' > /home/steven/apps/ArchiveBox-Docker/data/wallabag.txt

wget https://ideatrash.net/feed -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' > /home/steven/apps/ArchiveBox-Docker/data/ideatrash.txt

wget https://ideatrash.net/sitemap-1.xml -O- | sed -e 's:<url>:\n<url>:g' | sed -e 's:.*<loc>\(.*\)</loc>.*:\1:g' > /home/steven/apps/ArchiveBox-Docker/data/full_ideatrash.txt

wget "https://rss.stevesaus.me/public.php?op=rss&id=-2&view-mode=all_articles&key=9u5pdo5e07852179fb9" -O- | grep -e "<link href" | awk -F '"' '{print $2}' > /home/steven/apps/ArchiveBox-Docker/data/ttrss.txt

sudo docker-compose exec archivebox /bin/archive data/ideatrash.txt
sudo docker-compose exec archivebox /bin/archive data/shaarli.txt
sudo docker-compose exec archivebox /bin/archive data/wallabag.txt
sudo docker-compose exec archivebox /bin/archive data/ttrss.txt
sudo docker-compose exec archivebox /bin/archive data/full_ideatrash.txt



