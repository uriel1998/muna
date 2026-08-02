#!/bin/bash

##############################################################################
# muna, by Steven Saus 3 May 2022
# steven@stevesaus.com
# Licenced under the Apache License
##############################################################################

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export SCRIPT_DIR



function loud() {
##############################################################################
# loud outputs on stderr
##############################################################################
    if [ "${LOUD:-0}" -eq 1 ];then
		echo "$@" 1>&2
	fi
}



strip_tracking_url() {
	# because this is a bash function, it's using the variable $url as the returned
	# variable.  So there's no real "return" other than setting that var.
    local base_no_frag frag path qs cleaned_qs cleaned_url

    if [ -z "${url}" ]; then
        loud 'Usage: strip_tracking_url "URL"\n'
        return 1
    fi

    # Separate fragment (#...)
    case "${url}" in
        *\#*)
            frag="${url#*#}"
            base_no_frag="${url%%#*}"
            ;;
        *)
            frag=""
            base_no_frag="${url}"
            ;;
    esac

    # Separate query string (?...)
    case "${base_no_frag}" in
        *\?*)
            qs="${base_no_frag#*\?}"
            path="${base_no_frag%%\?*}"
            ;;
        *)
            qs=""
            path="${base_no_frag}"
            ;;
    esac

    # Strip known tracking parameters from query
    if [ -n "${qs}" ]; then
        cleaned_qs="$(
            printf '%s\n' "${qs}" | awk -F'&' '
                BEGIN {
                    # Extend this regexp with more tracking param names if you like
                    tracking = "^(utm_[^=]*|fbclid|gclid|dclid|mc_cid|mc_eid|igshid|pk_campaign|pk_source|pk_medium|pk_kwd|ss_source|pk_cid)$"
                }
                {
                    out = ""
                    for (i = 1; i <= NF; i++) {
                        key = $i
                        sub(/=.*/, "", key)   # strip everything after =
                        if (key ~ tracking) {
                            continue
                        }
                        if (out == "") {
                            out = $i
                        } else {
                            out = out "&" $i
                        }
                    }
                    print out
                }
            '
        )"
    else
        cleaned_qs=""
    fi

    # Rebuild cleaned URL
    cleaned_url="${path}"
    if [ -n "${cleaned_qs}" ]; then
        cleaned_url="${cleaned_url}?${cleaned_qs}"
    fi
    if [ -n "${frag}" ]; then
        cleaned_url="${cleaned_url}#${frag}"
    fi

    # If nothing changed, no need to test
    if [ "${cleaned_url}" = "${url}" ]; then
        loud "[info] No change after cleaning"
    else
		loud "[info] Cleaned url to ${url}"
		url="${cleaned_url}"
	fi
}

fetch_wayback_capture() {
##############################################################################
# Replace $url with the latest Wayback capture, or clear it on failure.
##############################################################################
    local firsturl encoded_url api_ia archive_url

    firsturl="${url}"
    loud "[info] Trying Internet Archive for ${firsturl}"

    encoded_url="$(
        printf '%s' "${firsturl}" \
        | sed \
            -e 's/%/%25/g' \
            -e 's/ /%20/g' \
            -e 's/#/%23/g' \
            -e 's/&/%26/g' \
            -e 's/+/%2B/g' \
            -e 's/?/%3F/g' \
            -e 's/=/%3D/g'
    )"

    api_ia="$(
        wget \
            --quiet \
            --timeout=5 \
            --tries=1 \
            --no-check-certificate \
            -erobots=off \
            --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0" \
            -O - \
            "https://archive.org/wayback/available?url=${encoded_url}"
    )"

    archive_url="$(
        printf '%s\n' "${api_ia}" \
        | grep -o '"url":"[^"]*"' \
        | head -1 \
        | sed -e 's/^"url":"//' -e 's/"$//'
    )"

    if [ -z "${archive_url}" ]; then
        SUCCESS=1
        url=""
        loud "[error] Web page is gone and not in Internet Archive!"
        loud "[error] For page ${firsturl}"
        return 1
    fi

    url="${archive_url}"
    SUCCESS=0
    loud "[info] Using Internet Archive version"
    loud "[info] ${url}"
    return 0
}

function unredirector {
    # because this is a bash function, it's using the variable $url as the returned
    # variable.  So there's no real "return" other than setting that var.
    SUCCESS=0

    # Handle Squarespace / similar redirectors that embed the real URL in ?u=
    # Example:
    # https://z6h1.engage.squarespace-mail.com/r?...&u=https%3A%2F%2Fwww.example.com%2F...&...
    if printf '%s\n' "${url}" | grep -qE '[?&]u='; then
        loud "[info] Detected embedded target URL in 'u=' parameter; extracting"

        # Extract the value of the u= parameter (still URL-encoded)
        local encoded_target
        encoded_target="$(
            printf '%s\n' "${url}" \
            | sed -n 's/.*[?&]u=\([^&]*\).*/\1/p'
        )"

        if [ -n "${encoded_target}" ]; then
            # URL-decode without python/perl:
            # 1) '+' -> space
            # 2) %XX -> corresponding byte via printf '%b'
            local decoded data
            data="${encoded_target//+/ }"
            decoded="$(printf '%b' "${data//%/\\x}")"
            if [[ "${decoded}" == *http* ]];then
                loud "[info] Unwrapped redirect to ${decoded}"
                url="${decoded}"
            else
                loud "[info] Failed to decode embedded URL; leaving original URL unchanged"
            fi
        else
            loud "[info] No 'u=' parameter value found; leaving original URL unchanged"
        fi
    fi

    # switching to wget b/c reasons
    local ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"
    local headers
    headers="$(
        wget \
            --spider \
            --server-response \
            --timeout=10 \
            --max-redirect=20 \
            --no-check-certificate \
            -erobots=off \
            --no-cache \
            --user-agent="${ua}" \
            "${url}" 2>&1
    )"
    local code
    code="$(
        printf '%s\n' "${headers}" \
        | awk '/HTTP\/[0-9.]* / {print $2; exit}'
    )"
    #checks for null as well
    if [ -z "${code}" ]; then
        fetch_wayback_capture
        return $?
    else
        if printf '%s\n' "${code}" | grep -q -e "3[0-9][0-9]"; then
            loud "[info] HTTP ${code} redirect"
            resulturl=""
            resulturl="$(
                printf '%s\n' "${headers}" \
                | grep -i "^[[:space:]]*Location:" \
                | tail -1 \
                | sed \
                    -e 's/^[[:space:]]*Location:[[:space:]]*//I' \
                    -e 's/[[:space:]]*\[following\][[:space:]]*$//' \
                    -e 's/\r$//'
            )"
            if [ -z "${resulturl}" ]; then
                loud "[info] No new location found"
                resulturl="${url}"
            else
                loud "[info] New location found"
                url="${resulturl}"
                strip_tracking_url
                loud "[info] REprocessing ${url}"
                headers="$(curl -k -s -m 5 --location -sS --head "${url}")"
                code="$(printf '%s\n' "${headers}" | head -1 | awk '{print $2}')"
                if printf '%s\n' "${code}" | grep -q -e "3[0-9][0-9]"; then
                    loud "[info] Second redirect; passing as-is"
                fi
            fi
        fi
        if printf '%s\n' "${code}" | grep -q -e "2[0-9][0-9]"; then
            loud "[info] HTTP ${code} exists"
            return 0
        fi
    fi

    loud "[info] HTTP ${code} unavailable, trying Internet Archive"
    fetch_wayback_capture
    return $?
}

unredirect() {
##############################################################################
# Backward-compatible name documented in the README.
##############################################################################
    unredirector "$@"
}

parse_args() {
##############################################################################
# Standalone option parser. Allows flags before or after the URL.
##############################################################################
    LOUD=0
    url=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -q)
                ;;
            --loud)
                LOUD=1
                ;;
            --)
                shift
                if [ "$#" -gt 0 ] && [ -z "${url}" ]; then
                    url="${1}"
                fi
                break
                ;;
            -*)
                echo "Unknown option: $1" 1>&2
                return 1
                ;;
            *)
                if [ -z "${url}" ]; then
                    url="${1}"
                else
                    echo "Unexpected extra argument: $1" 1>&2
                    return 1
                fi
                ;;
        esac
        shift
    done

    [ -n "${url}" ]
}


##############################################################################
# Are we sourced?
# From http://stackoverflow.com/questions/2683279/ddg#34642589
##############################################################################

# Try to execute a `return` statement,
# but do it in a sub-shell and catch the results.
# If this script isn't sourced, that will raise an error.
if ( return 0 2>/dev/null );then
    loud "[info] Function undirector ready to go."
else
    if [ "$#" = 0 ];then
        echo "Please call this as a function or with the url as the first argument."
        exit 99
    else
        if ! parse_args "$@"; then
            echo "Usage: muna.sh [-q] [--loud] URL" 1>&2
            exit 99
        fi
        SUCCESS=0
        strip_tracking_url
        unredirector
        if [ "${SUCCESS}" -eq 0 ];then
            strip_tracking_url
            # If it gets here, it has to be standalone
            echo "$url"
        else
            exit 99
        fi
    fi
fi
