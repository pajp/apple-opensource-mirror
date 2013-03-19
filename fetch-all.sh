curl http://www.opensource.apple.com|grep 'href="/release/mac-os-x'|sed -e 's/.*mac-os-x-\([0-9][^/]*\)\/.*/\1/'|sort|xargs -n 20 -P 5 ./fetch.sh 
