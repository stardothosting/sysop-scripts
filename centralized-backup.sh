# Dynamic backup script

currentmonth=`date "+%Y-%m-%d %H:%M:%S"`
currentdate=`date "+%Y-%m-%d%H_%M_%S"`
backup_email="your@email.com"
backup_dest="/your/backup/destination"
backup_server="your.backup.destination.server.com"
backup_user="root"

# Check User Input
if [ "$#" -lt 2 ]
then
        echo -e "\n\nUsage Syntax :"
        echo -e "./backup.sh [hostname] [folder1] [folder2] [folder3]"
        echo -e "Example : ./backup.sh hostname.com '/etc' '/usr/local/www' '/var/lib/mysql'\n\n"
        exit 1
fi

# get the server's hostname
host_name=`ssh -l root $1 "hostname"`
echo "Host name : $host_name"
if [ "$host_name" == "" ]
then
        host_name="unknown_$currentdate"
fi

echo "$host_name Offsite Backup Report: " $currentmonth > /var/log/backup.log
echo -e "----------------------------------------------------------" >> /var/log/backup.log
echo -e "" >> /var/log/backup.log

# Ensure permissions are correct
chown -R $backup_user:$backup_user $backup_dest/
ls -d $backup_dest/* | grep -v ".ssh\|.bash" | xargs -d "\n" chmod -R 775

# iterate over user arguments & set error level to 0
errors=0
for arg in "${@:2}"
do
        sanitize=`echo $arg | sed 's/[^\/]\/+$ //'`
        sanitize_dir=`echo $arg | awk -F '/' '{printf "%s", $2}'`
        # check if receiving directory exists
        if [ ! -d "$backup_dest/$host_name" ]
        then
                mkdir $backup_dest/$host_name
        fi
        # check if destination directory and subdirectories exist
        if [ ! -d "$backup_dest/$host_name$sanitize" ]
        then
                mkdir -p $backup_dest/$host_name$sanitize
        fi

        /usr/bin/ssh -o ServerAliveInterval=1 -o TCPKeepAlive=yes -l root $1 "/usr/bin/rsync -ravzp --progress $sanitize/ $backup_user@$backup_server:$backup_dest/$host_name$sanitize; echo $? > /tmp/bu_rlevel.txt" >> /var/log/backup.log 2>&1
        echo "/usr/bin/ssh -o ServerAliveInterval=1 -o TCPKeepAlive=yes -l root $1 \"/usr/bin/rsync -ravzp --progress  $sanitize/ $backup_user@$backup_server:$backup_dest/$host_name$sanitize\""
        runlevel=`ssh -l root $1 "cat /tmp/bu_rlevel.txt"`
        echo "Runlevel : $runlevel"

        if [ "$runlevel" -ge 1 ]
        then
                errors=$((counter+1))
        else
                echo -e "Script Backup for $arg Completed Successfully!" >> /var/log/backup.log 2>&1
        fi

done


# Check error level
if [ $errors -ge 1 ]
then
        echo -e "There were some errors in the backup job for $host_name, please investigate" >> /var/log/backup.log 2>&1
        cat /var/log/backup.log | mail -s "$host_name Backup Job failed" $backup_email
else
        cat /var/log/backup.log | mail -s "$host_name Backup Job Completed" $backup_email
fi
