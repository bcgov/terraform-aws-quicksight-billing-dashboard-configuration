import boto3

s3_client = boto3.client('s3')

source_bucket = 'example-source-bucket' # Source bucket name in the management account with the existing cur data
destination_bucket = 'example-destination-bucket' # Destination bucket in the management account that is created by the terraform solution to copy the existing cur data
base_prefix = 'example_base_prefix/' #Base prefix in our case {Management Account id}/cur/ where the cur data is stored
old_identifier = 'Exsisting CUR NAME' # Name of the cost and usage report as the AWS CUR uses this name to name the data stored in the s3. In our case the name was Cost-and-Usage-Report
new_identifier = 'New CUR Name'  # Name of the new cost and usage report created as the AWS CUR uses this name to name the data stored in the s3. In our case the name was Cost-and-Usage-Report

def rename_and_copy_objects(source_bucket, destination_bucket, base_prefix, old_identifier, new_identifier):
    paginator = s3_client.get_paginator('list_objects_v2')
    search_prefix = f"{base_prefix}{old_identifier}/"  # Prefix to search for objects

    for page in paginator.paginate(Bucket=source_bucket, Prefix=search_prefix):
        if 'Contents' in page:
            for obj in page['Contents']:
                old_key = obj['Key']
                # Replace the identifier in the key
                new_key = old_key.replace(old_identifier, new_identifier)

                # Copy the object to the new key in the destination bucket
                copy_source = {'Bucket': source_bucket, 'Key': old_key}
                s3_client.copy_object(Bucket=destination_bucket, CopySource=copy_source, Key=new_key)
                print(f"Copied {source_bucket}/{old_key} to {destination_bucket}/{new_key}")

rename_and_copy_objects(source_bucket, destination_bucket, base_prefix, old_identifier, new_identifier)
