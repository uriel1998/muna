# muna

Clean a series of links, resolving redirects and finding Wayback results if page is gone

![muna logo](https://raw.githubusercontent.com/uriel1998/muna/master/muna-open-graph.png "logo")

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [Installation](#4-installation)
 5. [Usage](#5-usage)
 6. [TODO](#6-todo)

***

## 1. About

Originally, `muna` was `uniredirector` for my program [agaetr](https://github.com/uriel1998/agaetr),
but grew to be quite a bit more multipurpose.  (The script in `agaetr` is now 
enhanced to be identical to `muna` but in name.

I ended up writing this because of [ArchiveBox](https://github.com/pirate/ArchiveBox). It's 
a great self-hosted archiving system, but when you throw a random list of URLs
(or worse, different types of RSS feeds) at it, you get... *mixed* results. It 
does not handle redirects too well, and if something is just 404, you're out of 
luck.  So I wrote `feeds-in` to preprocess inputs. It's included here as a 
use example of how to use `muna` and the bash function `unredirect`.

`muna` is an old norse word meaning "call to mind, remember".

## 2. License

This project is licensed under the Apache License. For the full license, see `LICENSE`.

## 3. Prerequisites

* bash
* awk
* curl 
* wget
* sed

On many linux installations these may already be installed; if not, they're 
in your package manager.  (If you have to build *these* from source, you don't 
need *me* telling you how to do that!)

## 4. Installation


### muna

Clone or download this repository. Put `muna.sh` somewhere in your `$PATH` or 
call/source it explicitly.  

### feeds-in.sh

While this script is included here as an example, it is a fully functional 
DEATH ST... script. It's a functional script, appropriate to put in a cronjob 
to preprocess sources of URLs for `ArchiveBox`.  Or use it as the base of a 
script to meet your needs.

If you are using `feeds-in.sh` with `ArchiveBox`, you will need to edit 
these lines as appropriate for you:

```
APPDIR="/home/www-data/apps/ArchiveBox-Docker"
RAWDIR="$APPDIR/rawdata"
DATADIR="$APPDIR/data"
source "$APPDIR/muna.sh"

```

`APPDIR` should be to your `ArchiveBox` installation. `RAWDIR` is a work 
directory. `DATADIR` should be the data directory of your `ArchiveBox` 
installation.

There are several example feeds (starting around line 50). Each strips that 
particular RSS feed (or XML sitemap) down to a series of URLs, one per line, 
written in a text file.  The console output here is a progress bar unless 
there are errors. The text file is time-date stamped to avoid collisions and 
overwrites.

Then `feeds-in.sh` calls `ArchiveBox` to import that list of URLs. Uncomment 
the appropriate line in this section for your style of installation. Note that 
the *docker-compose* and standalone *docker* commands are quite different; 
don't confuse them!  (I won't tell you how I know... sigh.)

```
###############################START PARTS TO EDIT########################

# Uncomment the next line for non-docker installations
#./archive /"$OUTFILESHORT"    

# Uncomment the next line for docker-compose installations   
docker-compose exec archivebox /bin/archive /"$OUTFILESHORT"

# Uncomment the next line for docker *NOT DOCKER COMPOSE* installations
#cat "$OUTFILE" | docker run -i -v ~/ArchiveBox:/data nikisweeting/archivebox
    
```

## 5. Usage

### muna

If there's a redirect, whether from a shortener or, say, redirected to HTTPS, 
`muna` will follow that and change the variable `"$url"` (or return to STDOUT) 
the appropriate URL. If there is any other error (including if the page is gone or 
the server has disappeared), it will see if the page is saved at the [Internet Archive](https://archive.org) 
and return the latest capture instead.  If it cannot find a copy anywhere, it 
changes the variable `"$url"` to a NULL string and returns nothing, 
exiting with the exit code `99`.

### Standalone

`muna.sh [-q] URL`

 * -q : If run standalone, it will return nothing to STDOUT except for the unredirected URL. Some error messages may print to STDERR.

### As a function

Put this line at the top of your script.

`source path/to/muna`
    
In your script, the variable `$url` must be set before calling the function 
`unredirect`. Afterward, if a successful match was made, `$url` will be 
set appropriately. If no match was made, `$url` will be set to NULL. Like
this example in `feeds-in.sh`.
    
```
url=$(printf "%s" "$line")
unredirector 
if [ ! -z "$url" ];then  #yup, that url exists
    echo "$url" >> "$OUTFILE"
fi     
```

### feeds-in.sh

`bash ./feeds-in.sh`
    
Seriously, that's it. If you edited things in the script to meet your system, then you should be done.
    
## 6. TODO


### Roadmap:

