#!/bin/bash -xe
# Cronjob to backup gitlab to S3 bucket
 
gitlab_etc_folder=/etc/gitlab
day=$(date +%Y.%m.%d)
tmp_folder=/tmp/gitlab-backup-$day
gitlab_etc_backup=$tmp_folder/gitlab-etc-files-$day.tar.gz
gitlab_backup_folder=/var/opt/gitlab/backups
gitlab_s3_bucket="s3://s3_bucket_where_to_backup_gitlab"
 
retention_policy=14
remove_backups_older_than=$(date -d "$retention_policy days ago" +%Y.%m.%d)
 
#remove $tmp_folder if for some reason such folder exists
if [ -d $tmp_folder ]; then
  echo "$tmp_folder exists. Remove $tmp_folder"
  rm -rf $tmp_folder
fi
 
echo "Create $tmp_folder - where to put gitlab backups"
mkdir $tmp_folder
 
echo "Clean up backup directory.'rm -f $gitlab_backup_folder/*.tar'"
rm -f $gitlab_backup_folder/*.tar
 
echo "Create archive on $gitlab_folder"
tar czf $gitlab_etc_backup $gitlab_etc_folder
 
echo "Creating a backup of the Gitlab system into $tmp_folder"
gitlab-rake gitlab:backup:create
 
echo "Move current backup from $gitlab_backup_folder to $tmp_folder"
mv $gitlab_backup_folder/*.tar $tmp_folder
 
echo "Upload to $gitlab_s3_bucket"
aws s3 cp $tmp_folder/ $gitlab_s3_bucket/gitlab-backup-$day --recursive
 
#Get backups uploaded to S3
aws s3 ls $gitlab_s3_bucket | awk '{print $2}'|  sed 's:/$::'| awk -F '-' '{print$3}' > ./git_backups
 
#retention policy
while read backup ; do
  if [[ $remove_backups_older_than > $backup ]]; then
    echo "Backup from $backup will be deleted. It's older than $retention_policy days"
    aws s3 rm $gitlab_s3_bucket/gitlab-backup-$backup --recursive
    removed_backup=1
  fi
done < ./git_backups
 
if [ ! $removed_backup ]; then
   echo "No backup from S3 was removed."
fi
 
echo "Remove $tmp_folder"
rm -rf $tmp_folder ./git_backups
