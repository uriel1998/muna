#!/bin/bash
  
# because this is a bash function, it's using the variable $url as the returned
# variable.  So there's no real "return" other than setting that var.

function unredirector {
    headers=$(curl --fail --connect-timeout 20 --location -sS --head "$url")
    code=$(echo "$headers" | head -1 | awk '{print $2}')
    
    #check for null as well
    if [ -z "$code" ];then
        echo "[info] Page/server not found, trying Internet Archive" >&2;
        firsturl="$url"
        url=$(printf "https://web.archive.org/web/*/%s" "$url")
        headers=$(curl --fail --connect-timeout 20 --location -sS --head "$url")
        code=$(echo "$headers" | head -1 | awk '{print $2}')
        if [ -z "$code" ];then
            echo "[error] Web page is gone and not in Internet Archive!" >&2;
            echo "[error] For page $firsturl" >&2;
            url=""  # Removing invalid variable.
            firsturl="" #cleaning up mess
        else
            echo "[info] Found on internet archive." 
        fi
    else
        if echo "$code" | grep -q -e "3[0-9][0-9]";then
            echo "[info] HTTP $code redirect"    
            resulturl=""
            resulturl=$(wget -O- --server-response "$url" 2>&1 | grep "^Location" | tail -1 | awk -F ' ' '{print $2}')
            if [ -z "$resulturl" ]; then
                echo "[info] No new location found" 
                resulturl=$(echo "$url")
            else
                echo "[info] New location found" 
                url=$(echo "$resulturl")
                echo "[info] REprocessing $url" 
                headers=$(curl --connect-timeout 20 --location -sS --head "$url")
                code=$(echo "$headers" | head -1 | awk '{print $2}')
                if echo "$code" | grep -q -e "3[0-9][0-9]";then
                    echo "[info] Second redirect; passing as-is" 
                fi
            fi
        fi
        if echo "$code" | grep -q -e "2[0-9][0-9]";then
            echo "[info] HTTP $code exists" 
        fi
    fi
}

##############################################################################
# Are we sourced?
# From http://stackoverflow.com/questions/2683279/ddg#34642589
##############################################################################

# Try to execute a `return` statement,
# but do it in a sub-shell and catch the results.
# If this script isn't sourced, that will raise an error.
$(return >/dev/null 2>&1)

# What exit code did that give?
if [ "$?" -eq "0" ];then
    echo "[info] Function undirector ready to go."
else
    if [ -z "$1" ];then
        echo "Please call this as a function or with the url as the first argument."
    else
        echo "$1"
        url="$1"
        unredirector    
    fi
fi

