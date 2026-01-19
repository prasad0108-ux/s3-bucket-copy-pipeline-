#!/bin/bash
set -e

SOURCE_BUCKET=$1
DEST_BUCKET=$2
DRY_RUN=$3
REGION=af-south-1

if [[ -z "$SOURCE_BUCKET" || -z "$DEST_BUCKET" ]]; then
  echo "❌ Usage: s3_copy.sh <source-bucket> <destination-bucket> <dry-run:true|false>"
  exit 1
fi

echo "🔐 AWS Identity"
aws sts get-caller-identity

echo "📦 Source bucket: $SOURCE_BUCKET"
echo "📦 Destination bucket: $DEST_BUCKET"
echo "🧪 Dry run: $DRY_RUN"

aws s3 ls s3://$SOURCE_BUCKET
aws s3 ls s3://$DEST_BUCKET

if [ "$DRY_RUN" = "true" ]; then
  echo "🧪 DRY RUN: Listing objects only"
  aws s3 ls s3://$SOURCE_BUCKET --recursive
  echo "✅ Dry run completed successfully"
  exit 0
fi

echo "🚀 Copying data..."
aws s3 sync s3://$SOURCE_BUCKET s3://$DEST_BUCKET --only-show-errors

SRC_COUNT=$(aws s3 ls s3://$SOURCE_BUCKET --recursive | wc -l)
DEST_COUNT=$(aws s3 ls s3://$DEST_BUCKET --recursive | wc -l)

echo "Source objects: $SRC_COUNT"
echo "Destination objects: $DEST_COUNT"

if [ "$DEST_COUNT" -lt "$SRC_COUNT" ]; then
  echo "❌ Copy validation failed"
  exit 1
fi

echo "🎉 SUCCESS: Data copied successfully"
