const {
    OrganizationsClient,
    ListAccountsCommand,
    ListTagsForResourceCommand,
  } = require("@aws-sdk/client-organizations");
  const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
  const {
    AthenaClient,
    StartQueryExecutionCommand,
    GetQueryExecutionCommand,
  } = require("@aws-sdk/client-athena");

  const RLS_CSV_FOLDER_URI = process.env.RLS_CSV_FOLDER_URI;
  const ACCOUNT_MAPPING_TABLE_NAME = process.env.ACCOUNT_MAPPING_TABLE_NAME;
  const COST_AND_USAGE_REPORT_TABLE = process.env.COST_AND_USAGE_REPORT_TABLE;

  const orgClient = new OrganizationsClient({ region: "ca-central-1" });
  const s3Client = new S3Client({ region: "ca-central-1" });
  const athenaClient = new AthenaClient({ region: "ca-central-1" });

  async function getOrgAccounts() {
    let input = {};
    let response = {};
    let result = [];
    let accountMap = {};

    const command = new ListAccountsCommand(input);
    response = await orgClient.send(command);
    result.push(...response.Accounts);

    while (response.NextToken) {
      if (response.NextToken === null) break;
      input.NextToken = response.NextToken;
      response = await orgClient.send(command);
      result.push(...response.Accounts);
    }

    for (const account of result) {
      if (account.Status === "ACTIVE" && account.JoinedMethod === "CREATED") {
        accountMap[account.Id] = {
          account_name: account.Name,
          account_email_id: account.Email,
        };

        const accountTags = await orgClient.send(
          new ListTagsForResourceCommand({
            ResourceId: account.Id,
          })
        );

        if (accountTags.Tags.length > 0) {
          for (const tag of accountTags.Tags) {
            switch (tag.Key) {
              case "ministry_name":
                accountMap[account.Id].ministry_name = tag.Value;
                break;
              case "billing_group":
                accountMap[account.Id].billing_group = tag.Value;
                break;
            }
          }
        }
      }
    }
    return accountMap;
  }

  exports.handler = async function () {
    const accountMap = await getOrgAccounts();

    let csvData = "";
    csvData +=
      "account_id,account_name,account_email_id,ministry_name,billing_group\n";
    for (const [accountId, account] of Object.entries(accountMap)) {
      let ministryName = account.ministry_name || "None";
      let billingGroup = account.billing_group || "None";
      csvData += `${accountId},${account.account_name},${account.account_email_id},${ministryName},${billingGroup}\n`;
    }
    console.log("CSV data:\n", csvData);

    try {
      const s3Response = await s3Client.send(
        new PutObjectCommand({
          Bucket: RLS_CSV_FOLDER_URI.split("/")[2],
          Key: "account-map/account_map.csv",
          Body: csvData,
          ContentType: "text/csv",
        })
      );

      if (s3Response.$metadata.httpStatusCode === 200) {
        console.log("Successfully uploaded CSV to S3. Response: ", s3Response);
        const athenaResponse = await athenaClient.send(
          new StartQueryExecutionCommand({
            QueryString: `CREATE OR REPLACE VIEW "account_map" AS 
            SELECT DISTINCT
              a.line_item_usage_account_id "account_id"
            , a.bill_payer_account_id "parent_account_id"
            , b.account_name
            , b.account_email_id
            , b.ministry_name
            , b.billing_group
            FROM
              ((
              SELECT DISTINCT
                line_item_usage_account_id
              , bill_payer_account_id
              FROM
              cid_cur.\`${COST_AND_USAGE_REPORT_TABLE}\`
            )  a
            LEFT JOIN (
              SELECT DISTINCT
                "lpad"("account_id", 12, '0') "account_id"
              , account_name
              , account_email_id
              , ministry_name
              , billing_group
              FROM
                cid_cur.${ACCOUNT_MAPPING_TABLE_NAME}
            )  b ON (b.account_id = a.line_item_usage_account_id))
            `,
            QueryExecutionContext: {
              Database: "cid_cur",
              Catalog: "AwsDataCatalog",
            },
            WorkGroup: "CID",
          })
        );
        console.log("Checking status of view creation...");
        const getQueryExecutionResponse = await athenaClient.send(
          new GetQueryExecutionCommand({
            QueryExecutionId: athenaResponse.QueryExecutionId,
          })
        );
        if (getQueryExecutionResponse.QueryExecution.Status.State === "FAILED") {
          throw new Error("View creation failed.");
        } else if (
          getQueryExecutionResponse.QueryExecution.Status.State === "QUEUED" ||
          getQueryExecutionResponse.QueryExecution.Status.State === "RUNNING"
        ) {
          console.log("View creation queued or running. Check back later.");
        } else {
          console.log("View creation successful.");
        }
      } else {
        throw new Error("Error uploading CSV to S3.");
      }
    } catch (err) {
      throw err;
    }
  };