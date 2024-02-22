#!/bin/bash

# aws configure information
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

# PostgreSQL database information
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
BUCKET_NAME=$BUCKET_NAME

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID && \
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY && \
aws configure set default.region $AWS_DEFAULT_REGION && \
aws configure set output json   

# Backup file
BACKUP_File=$BACKUP_FILE

# Download backup file from S3
echo "Downloading backup file from S3..."
aws s3 cp s3://$S3_BUCKET_NAME/$BACKUP_FILE /tmp/backup_file.dump

# Restore backup to PostgreSQL database
echo "Restoring backup to PostgreSQL database..."
PGPASSWORD=$DB_PASSWORD pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c /tmp/backup_file.dump

if [ $? -eq 0 ]; then
    echo "Restore successful from file: $BACKUP_FILE"
else
    echo "Restore failed."
fi