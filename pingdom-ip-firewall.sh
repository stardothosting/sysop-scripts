#!/bin/sh
# Script to dynamically add / update pingdom ips to the CSF firewall allow

configfile="/etc/csf/csf.allow"
newfile="/tmp/pingdom.txt"
oldfile="/tmp/pingdom_old.txt"
commmand="PINGDOM"

# get ips into temp file
echo "# PINGDOM BEGIN #" > $newfile
wget --quiet -O- https://www.pingdom.com/rss/probe_servers.xml | perl -nle 'print $1 if /IP: (([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5]));/' | sort -n -t . -k1,1 -k2,2 -k3,3 -k4,4 >> $newfile
echo "# PINGDOM END #" >> $newfile

# check if old/new files exist
if [[ ! -f $oldfile ]]; then
        touch $oldfile
fi

# compare old and new pingdom list
diff=$(diff $newfile $oldfile)

# if old and new pingdom ips are different
if [ "$diff" != "" ]
then
        # remove contents of old pingdom ips
        sed -i '/PINGDOM BEGIN/,/PINGDOM END/d' $configfile
        # append pingdom ips to csf allow
        cat $newfile >> $configfile 2>&1
        # move pingdom ip file to old for further comparisons
        rm -rf $oldfile > /dev/null 2>&1
        mv -f $newfile $oldfile > /dev/null 2>&1
        # reload csf rules
        /usr/sbin/csf -r > /dev/null 2>&1
fi
