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
            echo "[info] Found on internet archive." >&2;
        fi
    else
        if echo "$code" | grep -q -e "3[0-9][0-9]";then
            echo "[info] HTTP $code redirect" >&2;      
            resulturl=""
            resulturl=$(wget -O- --server-response "$url" 2>&1 | grep "^Location" | tail -1 | awk -F ' ' '{print $2}')
            if [ -z "$resulturl" ]; then
                echo "[info] No new location found" >&2;
                resulturl=$(echo "$url")
            else
                echo "[info] New location found" >&2;
                url=$(echo "$resulturl")
                echo "[info] REprocessing $url" >&2;
                headers=$(curl --connect-timeout 20 --location -sS --head "$url")
                code=$(echo "$headers" | head -1 | awk '{print $2}')
                if echo "$code" | grep -q -e "3[0-9][0-9]";then
                    echo "[info] Second redirect; passing as-is" >&2;
                fi
            fi
        fi
        if echo "$code" | grep -q -e "2[0-9][0-9]";then
            echo "[info] HTTP $code exists" >&2;
        fi
    fi
}


#main if not sourced

if [ -z "$1" ];then
    echo "Please call this as a function or with the url as the first argument."
else
    echo "$1"
    url="$1"
    unredirector    
fi