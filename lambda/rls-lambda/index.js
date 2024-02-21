const https = require("node:https");
const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const {
  QuickSightClient,
  CreateIngestionCommand,
} = require("@aws-sdk/client-quicksight");

const SECRET_NAME = process.env.SECRET_NAME;
const CLIENT_ID_SECRET_KEY = process.env.CLIENT_ID_SECRET_KEY;
const CLIENT_SECRET_SECRET_KEY = process.env.CLIENT_SECRET_SECRET_KEY;
const BCGOV_ROLES_FOR_ACCESS = process.env.BCGOV_ROLES_FOR_ACCESS;
// const fs = require('fs').promises;

const secretsManagerClient = new SecretsManagerClient({
  region: "ca-central-1",
});
const s3Client = new S3Client({
  region: "ca-central-1",
});
const quickSightClient = new QuickSightClient({
  region: "ca-central-1",
});

const KC_URL = process.env.KEYCLOAK_URL;
const REALM_NAME = process.env.REALM_NAME;
const DATASET_ARN = process.env.DATASET_ARN;
const RLS_CSV_FOLDER_URI = process.env.RLS_CSV_FOLDER_URI;
const AWS_ACCOUNT_ID = process.env.AWS_ACCOUNT_ID;
const QUICKSIGHT_CLIENT_NAME = process.env.QUICKSIGHT_CLIENT_NAME;
const AWS_CLIENT_NAME = process.env.AWS_CLIENT_NAME;

let bearerToken = "";

async function httpsRequest(method, path) {
  const options = {
    hostname: KC_URL,
    port: 443,
    path: path,
    method: method,
    headers: {
      Authorization: "Bearer " + bearerToken,
    },
  };

  const response = await new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => resolve(data));
    });
    req.on("error", (error) => reject(error));
    req.end();
  });

  return JSON.parse(response);
}
exports.handler = async function () {
  const authOptions = {
    hostname: KC_URL,
    port: 443,
    path: `/auth/realms/${REALM_NAME}/protocol/openid-connect/token`,
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
  };

  let response;

  try {
    response = await secretsManagerClient.send(
      new GetSecretValueCommand({
        SecretId: SECRET_NAME,
      })
    );
  } catch (error) {
    throw error;
  }

  const CLIENT_ID = JSON.parse(response.SecretString)[CLIENT_ID_SECRET_KEY];
  const CLIENT_SECRET = JSON.parse(response.SecretString)[
    CLIENT_SECRET_SECRET_KEY
  ];

  const clientCredentials = {
    grant_type: "client_credentials",
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
  };

  const token = await new Promise((resolve, reject) => {
    const req = https.request(authOptions, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        const token = JSON.parse(data).access_token;
        resolve(token);
      });
      console.log(data);
    });
    req.write(new URLSearchParams(clientCredentials).toString());
    req.on("error", (error) => reject(error));
    req.end();
  });

  if (token) {
    bearerToken = token;
  } else {
    throw new Error(
      "Error getting bearer token. Please check client credentials and try again."
    );
  }

  const realmClients = await httpsRequest(
    "GET",
    `/auth/admin/realms/${REALM_NAME}/clients`
  );

  const qsClient = realmClients.filter(
    (client) => client.clientId === QUICKSIGHT_CLIENT_NAME
  );

  const awsClient = realmClients.filter(
    (client) => client.clientId === AWS_CLIENT_NAME
  );

  const users = await httpsRequest(
    "GET",
    `/auth/admin/realms/${REALM_NAME}/users`
  );
  var rlsMap = [];

  for (const user of users) {
    const quickSightRoles = await httpsRequest(
      "GET",
      `/auth/admin/realms/${REALM_NAME}/users/${user["id"]}/role-mappings/clients/${qsClient[0].id}/composite`
    );  // For each user check what role user has access to based on the quicksight client

    if (quickSightRoles.length > 0) {
      for (const role of quickSightRoles) {
        const quickSightRoleName = role.name.split(",")[0].split("/")[1];
        console.log(quickSightRoleName)

        // const awsAccountIds = await httpsRequest(
        //   "GET",
        //   `/auth/admin/realms/${REALM_NAME}/users/${user["id"]}/role-mappings/clients/${awsClient[0].id}/composite`
        // ) // For each user check what aws client roles does the user has access to.
        //   .then((roles) => {
        //     return roles.map((role) => role.name.split(":")[4]);
        //   })
        //   .then((roles) => {
        //     return [...new Set(roles)];
        //   });

        // rlsMap[`${quickSightRoleName}/${user.email}`] = awsAccountIds;

        //modify code from here 
        // For each user check what AWS client roles does the user has access to.
          const awsRoles = await httpsRequest(
            "GET",
            `/auth/admin/realms/${REALM_NAME}/users/${user["id"]}/role-mappings/clients/${awsClient[0].id}/composite`
          );
          console.log(awsRoles)
          // Filter roles to only include those containing 'WORKLOAD_billing_viewer' in their name.
          const filteredRoles = awsRoles.filter(role => role.name.includes(BCGOV_ROLES_FOR_ACCESS));

          // Extract account IDs from the filtered roles.
          const awsAccountIds = filteredRoles.map(role => {
            const match = role.name.match(/arn:aws:iam::(\d+):role\/[^,]+/);
            return match ? match[1] : null;
          }).filter(accountId => accountId !== null); // Ensure null values are removed.

          // Deduplicate account IDs
          const uniqueAwsAccountIds = [...new Set(awsAccountIds)];

          rlsMap[`${quickSightRoleName}/${user.email}`] = uniqueAwsAccountIds;

      }
    }
  }

  let csvData = "";
  for (const [username, accounts] of Object.entries(rlsMap)) {
    if (accounts.length > 1) {
      csvData += `${username},"${accounts.join(",")}"\n`;
    } else {
      csvData += `${username},${accounts.join(",")}\n`;
    }
  }

  console.log("CSV data:\n", csvData);
  // try {
  //   await fs.writeFile('rls.csv', csvData);
  //   console.log('CSV file has been saved/overwritten successfully.');
  // } catch (error) {
  //   console.error('Error writing CSV file:', error);
  // }


  try {
    const s3Response = await s3Client.send(
      new PutObjectCommand({
        Bucket: RLS_CSV_FOLDER_URI.split("/")[2],
        Key: RLS_CSV_FOLDER_URI.split("/").slice(3).join("/") + "rls.csv",
        Body: csvData,
        ContentType: "text/csv",
      })
    );

    if (s3Response.$metadata.httpStatusCode === 200) {
      console.log("Successfully uploaded CSV to S3. Response: ", s3Response);

      const date = new Date().toISOString().split("T");
      const formattedDate = `${date[0]}-${date[1]
        .substring(0, 8)
        .replace(/:/g, "-")}`;

      const ingestionResponse = await quickSightClient.send(
        new CreateIngestionCommand({
          DataSetId: DATASET_ARN.split("/")[1],
          IngestionId: formattedDate,
          IngestionType: "FULL_REFRESH",
          AwsAccountId: AWS_ACCOUNT_ID,
        })
      );
      if (ingestionResponse.$metadata.httpStatusCode === 201) {
        console.log(
          "Successfully started data refresh on S3 RLS dataset. Response: ",
          ingestionResponse
        );
      }
    } else {
      throw new Error("Error uploading CSV to S3.");
    }
  } catch (error) {
    throw error;
  }
};