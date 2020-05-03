#!/bin/bash

source "$SCRIPT_DIR/unredirector.sh"
APPDIR="/home/steven/apps/ArchiveBox-Docker"
RAWDIR="$APPDIR/rawdata"
DATADIR="$APPDIR/data"


if [ ! -d "$RAWDIR" ]; then
    mkdir -p "$RAWDIR"
fi

if [ ! -d "$DATADIR" ]; then
    mkdir -p "$DATADIR"
fi


wget https://shaarli.stevesaus.me/?do=atom -O- | grep -e "<link href" | awk -F '"' '{print $2}' > $RAWDIR/shaarli.txt

wget https://bag.faithcollapsing.com/ssaus/kJ8VHqEOOfzkp7/unread.xml -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' > $RAWDIR/data/wallabag.txt

wget https://ideatrash.net/feed -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' > $RAWDIR/ideatrash.txt

wget https://ideatrash.net/sitemap-1.xml -O- | sed -e 's:<url>:\n<url>:g' | sed -e 's:.*<loc>\(.*\)</loc>.*:\1:g' > $RAWDIR/full_ideatrash.txt

wget "https://rss.stevesaus.me/public.php?op=rss&id=-2&view-mode=all_articles&key=9u5pdo5e07852179fb9" -O- | grep -e "<link href" | awk -F '"' '{print $2}' > $RAWDIR/ttrss.txt


# So that there aren't collisions or overwriting
time=`date +_%Y%m%d_%H%M%S` 
OUTFILE=$(printf "%s/parsed%s.txt" "$DATADIR" "$time")

#looping through files in rawdir
files=$(ls -A "$RAWDIR")
for f in $files;do

    
    #second loop
    
    while read line; do
    url=$(printf "%s" "$line")
    unredirector #because $url is now set
    if [ ! -z "$url" ];then  #yup, that url exists
        printf "%s" "$url" >> "$DATADIR/parsed
    
    fi
    # reading each line and doing stuff
    echo "Line No. $n : $line"
    n=$((n+1))
    done < $filename


    echo "Processing ${p%.*}..."
    send_funct=$(echo "${p%.*}_send")
    source "$SCRIPT_DIR/out_enabled/$p"
    echo "$SCRIPT_DIR/out_enabled/$p"
    eval ${send_funct}
    sleep 5
done

docker-compose exec archivebox /bin/archive data/ideatrash.txt
docker-compose exec archivebox /bin/archive data/shaarli.txt
docker-compose exec archivebox /bin/archive data/wallabag.txt
docker-compose exec archivebox /bin/archive data/ttrss.txt
docker-compose exec archivebox /bin/archive data/full_ideatrash.txt



