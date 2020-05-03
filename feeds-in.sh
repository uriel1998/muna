#!/bin/bash


##############################################################################
# Initi
##############################################################################

APPDIR="/home/steven/apps/ArchiveBox-Docker"
RAWDIR="$APPDIR/rawdata"
DATADIR="$APPDIR/data"
source "$APPDIR/unredirector.sh"

if [ ! -d "$RAWDIR" ]; then
    mkdir -p "$RAWDIR"
fi

if [ ! -d "$DATADIR" ]; then
    mkdir -p "$DATADIR"
fi


##############################################################################
# Progress bar
# From https://github.com/fearside/ProgressBar/
##############################################################################

function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}



wget -q https://shaarli.stevesaus.me/?do=atom -O- | grep -e "<link href" | awk -F '"' '{print $2}' > $RAWDIR/shaarli.txt

wget -q https://bag.faithcollapsing.com/ssaus/kJ8VHqEOOfzkp7/unread.xml -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' | grep -e "^h" > $RAWDIR/data/wallabag.txt

wget -q https://ideatrash.net/feed -O- | grep -e "<link>" | awk -F '>' '{print $2}' | awk -F '<' '{print $1}' | grep -e "^h"  > $RAWDIR/ideatrash.txt

wget -q https://ideatrash.net/sitemap-1.xml -O- | sed -e 's:<url>:\n<url>:g' | sed -e 's:.*<loc>\(.*\)</loc>.*:\1:g' | grep -e "^h" > $RAWDIR/full_ideatrash.txt

wget -q "https://rss.stevesaus.me/public.php?op=rss&id=-2&view-mode=all_articles&key=9u5pdo5e07852179fb9" -O- | grep -e "<link href" | awk -F '"' '{print $2}' | grep -e "^h" > $RAWDIR/ttrss.txt


# So that there aren't collisions or overwriting
time=`date +_%Y%m%d_%H%M%S` 
OUTFILE=$(printf "%s/parsed%s.txt" "$DATADIR" "$time")
OUTFILESHORT=$(printf "data/parsed%s.txt" "$time")
#looping through files in rawdir; this also allows you to slap a file of 
#urls (one per line) and have it get picked up and processed on the next run
files=$(ls -A "$RAWDIR")

totallines=$(wc -l "$RAWDIR/$f")

for f in $files;do
    echo "$f"
    i = 0
    
    #looping through each file    
    while read line; do
        ProgressBar $i $totallines
        line=$(echo "$line" | grep -e "^h")  #additional error checking for files just chucked in
        if [ ! -z "$line" ];then 
            url=$(printf "%s" "$line")
            unredirector #because $url is now set
            if [ ! -z "$url" ];then  #yup, that url exists; just skipping if it doesn't
                echo "$url" >> "$OUTFILE"
            fi 
        fi
        ((i++)
    done < "$RAWDIR/$f"
    
    # Removing the temporary file will go here after testing
done

# Maybe this should be written to a string and use eval? Not sure.
#docker-compose exec archivebox /bin/archive "$OUTFILESHORT"

# for later, looping and then cleaning the output file
#docker-compose exec archivebox /bin/archive data/ideatrash.txt
#docker-compose exec archivebox /bin/archive data/shaarli.txt
#docker-compose exec archivebox /bin/archive data/wallabag.txt
#docker-compose exec archivebox /bin/archive data/ttrss.txt
#docker-compose exec archivebox /bin/archive data/full_ideatrash.txt



