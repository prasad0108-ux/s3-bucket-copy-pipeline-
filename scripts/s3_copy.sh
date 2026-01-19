#!/bin/bash
set -e

RAW_SOURCE=$1
RAW_DEST=$2
SRC_REGION=$3
DEST_REGION=$4
DRY_RUN=$5

# -------- FUNCTION: Normalize bucket input --------
normalize_bucket() {
  local input=$1

  # If ARN → extract bucket name
  if [[ "$input" == arn:aws:s3:::* ]]; then
    echo "${input##arn:aws:s3:::}"
  else
    echo "$input"
  fi
}

SOURCE_BUCKET=$(normalize_bucket "$RAW_SOURCE")
DEST_BUCKET=$(normalize_bucket "$RAW_DEST")

echo "🔎 Normalized Source Bucket: $SOURCE_BUCKET"
echo "🔎 Normalized Destination Bucket: $DEST_BUCKET"

# -------- Validation --------
echo "🔐 AWS Identity"
aws sts get-caller-identity

echo "📦 Validating source bucket"
aws s3api head-bucket --bucket "$SOURCE_BUCKET" --region "$SRC_REGION"

echo "📦 Validating destination bucket"
aws s3api head-bucket --bucket "$DEST_BUCKET" --region "$DEST_REGION"

# -------- Dry Run --------
if [ "$DRY_RUN" = "true" ]; then
  echo "🧪 DRY RUN MODE ENABLED"
  aws s3 ls s3://$SOURCE_BUCKET --recursive --region "$SRC_REGION"
  echo "✅ Dry run completed successfully"
  exit 0
fi

# -------- Copy --------
echo "🚀 Starting cross-region copy"
aws s3 sync \
  s3://$SOURCE_BUCKET \
  s3://$DEST_BUCKET \
  --source-region "$SRC_REGION" \
  --region "$DEST_REGION" \
  --only-show-errors

# -------- Validation --------
SRC_COUNT=$(aws s3 ls s3://$SOURCE_BUCKET --recursive --region "$SRC_REGION" | wc -l)
DEST_COUNT=$(aws s3 ls s3://$DEST_BUCKET --recursive --region "$DEST_REGION" | wc -l)

echo "Source objects: $SRC_COUNT"
echo "Destination objects: $DEST_COUNT"

if [ "$DEST_COUNT" -lt "$SRC_COUNT" ]; then
  echo "❌ Copy validation failed"
  exit 1
fi

echo "🎉 SUCCESS: Data copied successfully"
