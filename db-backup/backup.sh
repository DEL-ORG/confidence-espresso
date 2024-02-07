#!/bin/bash
# PostgreSQL database details
DB_HOST="DB_HOST"
DB_PORT="DB_PORT"
DB_NAME="DB_NAME"
DB_USER="DB_USER"
DB_PASSWORD="DB_PASSWORD"

# Backup directory
BACKUP_DIR="/backup"

# Date format for the backup file
DATE_FORMAT=$(date +"%Y%m%d%H%M%S")

# Backup file name
BACKUP_FILE="/backup/${DB_NAME}_backup_${DATE_FORMAT}.sql"

# Set the PGPASSWORD environment variable for pg_dump
export PGPASSWORD=$DB_PASSWORD

# Create the backup using pg_dump with complete path/command
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > "$BACKUP_DIR/$BACKUP_FILE"

# Capture the exit code of the pg_dump command
PG_DUMP_EXIT_CODE=$?

# Unset the PGPASSWORD environment variable
unset PGPASSWORD

# Check if the backup was successful
if [ $PG_DUMP_EXIT_CODE -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_DIR/$BACKUP_FILE"

    # Remove backups older than 30 days
    find $BACKUP_DIR -name "*.sql" -type f -mtime +30 -exec rm {} \;
    echo "Old backups older than 30 days have been removed."
else
    echo "Backup failed with exit code $PG_DUMP_EXIT_CODE"
fi
aws s3 cp postgres-* s3://$BUCKET_NAME/	