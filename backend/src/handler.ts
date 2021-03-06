import { APIGatewayProxyEvent, APIGatewayProxyHandler, APIGatewayProxyResult } from 'aws-lambda';
import { ApiGatewayManagementApi, DynamoDB } from 'aws-sdk';
import 'source-map-support/register';

const ERROR = {
  INVALID_JSON: {
    code: 1,
    message: `無効なJSON形式です。`,
  },
  PASSWORD_NOT_SET: {
    code: 2,
    message: `パスワードが必要です。`,
  },
  PASSWORD_NOT_EXIST: {
    code: 3,
    message: `パスワードが存在しません。`,
  },
  PASSWORD_NOT_YET_VALID: {
    code: 4,
    message: `パスワードの有効期限が始まっていません。`,
  },
  PASSWORD_EXPIRED: {
    code: 5,
    message: `パスワードの有効期限が切れています。`,
  },
};

const apigateway = ({ domainName, stage }): ApiGatewayManagementApi => new ApiGatewayManagementApi({ endpoint: `${domainName}/${stage}` });
const dynamodb = new DynamoDB.DocumentClient();

export const hello: APIGatewayProxyHandler = async (event, _context) => {
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Go Serverless Webpack (Typescript) v1.0! Your function executed successfully!',
      input: event,
    }, null, 2),
  };
}

export const connect: APIGatewayProxyHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.debug('Starting Lambda handler: event=%s', JSON.stringify(event));
  await dynamodb.put({ TableName: process.env.DYNAMODB_CONNECTIONS, Item: { ConnectionId: event.requestContext.connectionId } }).promise();
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Connected',
    }),
  };
};

export const disconnect: APIGatewayProxyHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.debug('Starting Lambda handler: event=%s', JSON.stringify(event));
  await dynamodb.delete({ TableName: process.env.DYNAMODB_CONNECTIONS, Key: { ConnectionId: event.requestContext.connectionId } }).promise();
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Disconnected',
    }),
  };
};

async function checkPassword(body: string) {
  let parsed = null;
  try {
    parsed = JSON.parse(body);
  } catch (e) {
    return {
      error: ERROR.INVALID_JSON,
    };
  }
  if (typeof parsed !== "object") {
    return {
      error: ERROR.INVALID_JSON,
    };
  }
  const password = parsed.password;
  if (!password) {
    return {
      error: ERROR.PASSWORD_NOT_SET,
    };
  }
  const { Item } = await dynamodb.get({ TableName: process.env.DYNAMODB_PASSWORDS, Key: { Password: password } }).promise();
  if (!Item) {
    return {
      error: ERROR.PASSWORD_NOT_EXIST,
    };
  }
  const startTime = new Date(Item.StartTime).getTime();
  const endTime = new Date(Item.EndTime).getTime();
  const now = Date.now();
  if (now < startTime) {
    return {
      error: ERROR.PASSWORD_NOT_YET_VALID,
      startTime: Item.StartTime,
      endTime: Item.EndTime,
    };
  } else if (endTime < now) {
    return {
      error: ERROR.PASSWORD_EXPIRED,
      startTime: Item.StartTime,
      endTime: Item.EndTime,
    };
  }
  return {
    parsed,
    startTime: Item.StartTime,
    endTime: Item.EndTime,
  };
}

export const defaultMessage: APIGatewayProxyHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.debug('Starting Lambda handler: event=%s', JSON.stringify(event));
  const checkResult = await checkPassword(event.body);
  if (checkResult.error) {
    const { startTime, endTime } = checkResult;
    const { code, message } = checkResult.error;
    const api = new ApiGatewayManagementApi({ endpoint: `${event.requestContext.domainName}/${event.requestContext.stage}` });
    await api.postToConnection({
      ConnectionId: event.requestContext.connectionId,
      Data: JSON.stringify({
        code,
        message,
        startTime,
        endTime,
      }),
    }).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({}),
    };
  }
  const { parsed, startTime, endTime } = checkResult;
  const connections = await dynamodb.scan({ TableName: process.env.DYNAMODB_CONNECTIONS, ProjectionExpression: 'ConnectionId' }).promise();
  await Promise.all(connections.Items.map(async ({ ConnectionId }) => {
    try {
      const params: ApiGatewayManagementApi.Types.PostToConnectionRequest = {
        ConnectionId: ConnectionId,
        Data: JSON.stringify({
          code: 0,
          startTime,
          endTime,
          ...parsed,
          password: undefined,
        }),
      };
      const { domainName, stage } = event.requestContext;
      await apigateway({domainName, stage}).postToConnection(params).promise();
    } catch (e) {
      if (e.statusCode === 410) {
        await dynamodb.delete({ TableName: process.env.DYNAMODB_CONNECTIONS, Key: { ConnectionId: ConnectionId } }).promise();
      } else {
        throw e;
      }
    }
  }));
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'OK',
    }),
  };
}
