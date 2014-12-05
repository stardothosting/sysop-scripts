#!/bin/sh
# Offsite S3 backup script w/ duplicity

# credentials
export PASSPHRASE=temp
export AWS_ACCESS_KEY_ID=temp
export AWS_SECRET_ACCESS_KEY=temp

currentdate=`date "+%Y-%m-%d"`
backuplog="/var/log/offsite-s3-backup.log"
servername="SUZUKI-VARNISH"
dstpath="sdh-infrastructure/sdh-iwtf/iwtf-db"
srcpath="/etc /usr/local/bin /root"
emails="admin@stardothosting.com"

echo "$servername Offsite S3 Log: " $currentdate > $backuplog 2>&1
echo -e "---------------------------------------------" >> $backuplog 2>&1
echo -e "" >> $backuplog 2>&1

# build include variable
include=""
for cdir in $srcpath
do
	tmp=" --include ${cdir}"
	include=${include}${tmp}
done

# run duplicity with all needed parameters:
/usr/bin/duplicity $include --exclude "**" --s3-use-new-style --no-encryption --full-if-older-than 1M / s3://s3-external-1.amazonaws.com/$dstpath >> $backuplog 2>&1

# error checking
if [ "$?" -eq 1 ]
then
        echo -e "***$servername OFFSITE S3 JOB, THERE WERE ERRORS***" >> $backuplog 2>&1
        cat $backuplog | mail -s "$servername Offsite S3 Job failed" $emails
        exit 1
else
        echo -e "Script Completed Successfully!" >> $backuplog 2>&1
        cat $backuplog | mail -s "$servername Offsite S3 Job Completed" $emails
        exit 0
fi

# cleanup
/usr/bin/duplicity remove-older-than 3M --force s3://s3-external-1.amazonaws.com/$dstpath >> $backuplog 2>&1

# error checking
if [ "$?" -eq 1 ]
then
        echo -e "***$servername OFFSITE S3 CLEANUP JOB, THERE WERE ERRORS***" >> $backuplog 2>&1
        cat $backuplog | mail -s "$servername Offsite S3 Cleanup Job failed" $emails
        exit 1
else
        echo -e "Script Completed Successfully!" >> $backuplog 2>&1
        cat $backuplog | mail -s "$servername Offsite S3 Cleanup Job Completed" $emails
        exit 0
fi
