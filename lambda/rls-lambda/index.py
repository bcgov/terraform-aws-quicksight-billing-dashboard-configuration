from __future__ import annotations

import csv
import io
import os
from collections import defaultdict
from datetime import datetime
from itertools import islice
import re

import boto3
from botocore.exceptions import ClientError

IDENTITY_STORE_ID   = os.environ["IDENTITY_STORE_ID"]
BILLING_GROUP_REGEX = re.compile(os.environ["BILLING_GROUP_REGEX"], re.I)
READER_GROUP_NAME   = os.environ["QUICKSIGHT_READER_GROUP_NAME"]
QUICKSIGHT_DASHBOARD_ADMIN_GROUP_NAME    = os.environ["QUICKSIGHT_DASHBOARD_ADMIN_GROUP_NAME"]  # NEW

RLS_BUCKET = os.environ["RLS_CSV_BUCKET_NAME"]
RLS_KEY    = "rls/rls.csv"  

DATASET_ARN = os.environ["DATASET_ARN"]
QS_DATASET_ID = DATASET_ARN.split("/")[-1]
AWS_ACCOUNT_ID = os.environ["AWS_ACCOUNT_ID"]

REGION = os.environ.get("AWS_REGION", "ca-central-1")


ids = boto3.client("identitystore", region_name=REGION)
org = boto3.client("organizations",  region_name=REGION)
s3  = boto3.client("s3",             region_name=REGION)
qs  = boto3.client("quicksight",     region_name=REGION)


def paginate(method, key: str, **kwargs):
    while True:
        resp = method(**kwargs)
        yield from resp[key]
        if "NextToken" not in resp:
            break
        kwargs["NextToken"] = resp["NextToken"]


def list_billing_groups():
    # All groups whose display name matches BILLING_GROUP_REGEX pattern.
    return [
        g for g in paginate(
            ids.list_groups,
            "Groups",
            IdentityStoreId=IDENTITY_STORE_ID,
            MaxResults=50,
        )
        if BILLING_GROUP_REGEX.match(g["DisplayName"])
    ]


def list_accounts_for_plate(lp: str) -> set[str]:
    acct_ids = set()
    for acct in paginate(org.list_accounts, "Accounts"):
        tags = org.list_tags_for_resource(ResourceId=acct["Id"])["Tags"]
        tagged = any(t["Key"] == "billing_group" and t["Value"] == lp for t in tags)
        named  = lp in acct["Name"]  # fallback
        if tagged or named:
            acct_ids.add(acct["Id"])
    return acct_ids


def list_group_members(group_id: str):
    for m in paginate(
        ids.list_group_memberships,
        "GroupMemberships",
        IdentityStoreId=IDENTITY_STORE_ID,
        GroupId=group_id,
        MaxResults=50,
    ):
        yield m


def describe_user_email(user_id: str) -> str:
    u = ids.describe_user(IdentityStoreId=IDENTITY_STORE_ID, UserId=user_id)
    return u["UserName"]


def find_group_by_name(name: str) -> dict | None:
    for g in paginate(
        ids.list_groups,
        "Groups",
        IdentityStoreId=IDENTITY_STORE_ID,
        Filters=[{"AttributePath": "DisplayName", "AttributeValue": name}],
    ):
        if g["DisplayName"] == name:
            return g
    return None


def find_user_id_by_email(email: str) -> str | None:
    """IAM Identity Center v2 API lacks ListUsers; brute-force search groups."""
    email = email
    for g in paginate(
        ids.list_groups,
        "Groups",
        IdentityStoreId=IDENTITY_STORE_ID,
        MaxResults=50,
    ):
        for m in list_group_members(g["GroupId"]):
            u_email = describe_user_email(m["MemberId"]["UserId"])
            if u_email == email:
                return m["MemberId"]["UserId"]
    return None


def list_admin_users() -> set[str]:
    admin_group = find_group_by_name(QUICKSIGHT_DASHBOARD_ADMIN_GROUP_NAME)
    if not admin_group:
        print(f"Admin group {QUICKSIGHT_DASHBOARD_ADMIN_GROUP_NAME} not found. no admin users will get global access")
        return set()

    admin_emails = set()
    for memb in list_group_members(admin_group["GroupId"]):
        email = describe_user_email(memb["MemberId"]["UserId"])
        admin_emails.add(email)

    print(f"Found {len(admin_emails)} admin users in group {QUICKSIGHT_DASHBOARD_ADMIN_GROUP_NAME}")
    return admin_emails


def lambda_handler(event, _context):
    user_to_accts: dict[str, set[str]] = defaultdict(set)

    # users in this group get full access and should not be added again with specific accounts
    admin_users = list_admin_users()

    # print(list_billing_groups())
    for group in list_billing_groups():
        plate = group["DisplayName"].split("_")[3].lower()
        print(plate)
        account_ids = list_accounts_for_plate(plate)
        print(account_ids)

        for memb in list_group_members(group["GroupId"]):
            email = describe_user_email(memb["MemberId"]["UserId"])

            # skip account-specific mapping for admin users
            if email in admin_users:
                continue

            user_to_accts[email].update(account_ids)

    reader_group = find_group_by_name(READER_GROUP_NAME)
    if reader_group:
        # include admin users too, so they are also part of reader group reconcile
        reconcile_reader_group(reader_group["GroupId"], set(user_to_accts) | admin_users)
    else:
        print(f"Reader group {READER_GROUP_NAME} not found; skipping reconcile")

    # 3 ─ write CSV to S3
    csv_body = build_csv(user_to_accts, admin_users)  # CHANGED
    s3.put_object(Bucket=RLS_BUCKET, Key=RLS_KEY, Body=csv_body, ContentType="text/csv")
    print(f"Uploaded rls.csv with {len(user_to_accts) + len(admin_users)} users")
    print(user_to_accts)
    print(f"Admin users with full access: {admin_users}")

    # 4 ─ trigger QuickSight ingestion
    run_id = datetime.utcnow().isoformat(timespec="seconds").replace(":", "-")
    qs.create_ingestion(
        AwsAccountId=AWS_ACCOUNT_ID,
        DataSetId=QS_DATASET_ID,
        IngestionId=run_id,
        IngestionType="FULL_REFRESH",
    )
    print("QuickSight ingestion started")
    return {"status": "ok", "rows": len(user_to_accts) + len(admin_users)}


def build_csv(user_map: dict[str, set[str]], admin_users: set[str]) -> bytes:
    buf = io.StringIO()

    # admin users get blank account field = full access
    for email in sorted(admin_users):
        buf.write(f"{email},\n")

    for email, acct_set in sorted(user_map.items()):
        # extra guard
        if email in admin_users:
            continue
        joined = ",".join(sorted(acct_set))
        buf.write(f'{email},"{joined}"\n')

    return buf.getvalue().encode()


def reconcile_reader_group(group_id: str, desired_emails: set[str]):
    """Add missing users, remove users that does not need access inside the Reader group."""
    current_members = {
        describe_user_email(m["MemberId"]["UserId"]): m
        for m in list_group_members(group_id)
    }

    # additions
    for email in desired_emails - current_members.keys():
        uid = find_user_id_by_email(email)
        if uid:
            ids.create_group_membership(
                IdentityStoreId=IDENTITY_STORE_ID,
                GroupId=group_id,
                MemberId={"UserId": uid},
            )

    # removals
    for email in current_members.keys() - desired_emails:
        try:
            ids.delete_group_membership(
                IdentityStoreId=IDENTITY_STORE_ID,
                MembershipId=current_members[email]["MembershipId"],
            )
        except ClientError as e:
            print(f"Could not remove {email}: {e}")