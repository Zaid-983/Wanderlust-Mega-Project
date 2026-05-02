# ──────────────────────────────────────────────────────────────────
# STEP 1: S3 Bucket — stores the terraform.tfstate file remotely
# ──────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "terraform_state" {
  bucket = "wanderlust-terraform-state-bucket-v2"   # must be globally unique
                                                  # change to your project name

  # Prevent accidental deletion of state bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Project     = "wanderlust"
    ManagedBy   = "terraform"
  }
}

# Enable versioning — keeps full history of every state file change.
# If a bad apply corrupts state, you can restore a previous version.
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"    # CRITICAL — never disable this on state buckets
  }
}

# Block ALL public access — state files must NEVER be public.
# They contain your full infrastructure config including secrets.
resource "aws_s3_bucket_public_access_block" "terraform_state_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────────────────────────────
# STEP 2: DynamoDB Table — provides STATE LOCKING
#
# WHY STATE LOCKING?
#   Without locking, if two engineers run `terraform apply`
#   simultaneously, both read the same state → both write back
#   different states → state corruption / duplicate resources.
#
# HOW IT WORKS:
#   terraform apply starts  → writes lock entry to DynamoDB
#   another apply tries     → sees lock → BLOCKED with error
#   first apply finishes    → deletes lock entry
#   second apply proceeds   → gets lock → runs safely
#
# The table MUST have LockID as the partition key (Terraform requirement).
# ──────────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "wanderlust-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"  # no provisioned capacity needed
                                     # lock ops are infrequent
  hash_key     = "LockID"           # MUST be exactly "LockID"

  attribute {
    name = "LockID"
    type = "S"                       # S = String type
  }

  # Protect lock table from accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "Terraform State Lock Table"
    Project   = "wanderlust"
    ManagedBy = "terraform"
  }
}

# ──────────────────────────────────────────────────────────────────
# STEP 3: Terraform Backend Configuration
#
# This tells Terraform WHERE to store and read state from.
#
# ⚠️  IMPORTANT RULES:
#   - This block cannot use variables (${var.x} won't work here)
#   - Values must be hardcoded strings
#   - After changing this block, run: terraform init -reconfigure
#   - First time setup: terraform init (migrates local → S3)
# ──────────────────────────────────────────────────────────────────
terraform {
  backend "s3" {
    bucket         = "wanderlust-terraform-state-bucket-v2"  # same as above
    key            = "/terraform.tfstate"                 # path inside bucket
                                                          # format: project/env/terraform.tfstate
    region         = "us-east-2"                          # change to your AWS region

    # State locking via DynamoDB
    dynamodb_table = "wanderlust-terraform-state-lock"    # same as above
  }


}
