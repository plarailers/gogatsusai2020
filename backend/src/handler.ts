import { APIGatewayProxyEvent, APIGatewayProxyHandler, APIGatewayProxyResult } from 'aws-lambda';
import { ApiGatewayManagementApi, DynamoDB } from 'aws-sdk';
import 'source-map-support/register';

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

export const defaultMessage: APIGatewayProxyHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.debug('Starting Lambda handler: event=%s', JSON.stringify(event));
  try {
    const parsed = JSON.parse(event.body);
    const password = parsed.password;
    if (password === undefined) {
      throw new Error('パスワードが必要です。');
    }
    const result = await dynamodb.get({ TableName: process.env.DYNAMODB_PASSWORDS, Key: { Password: password } }).promise();
    if (result.Item) {
      const { Item } = result;
      const startTime = new Date(Item.StartTime).getTime();
      const endTime = new Date(Item.EndTime).getTime();
      const now = Date.now();
      if (now < startTime) {
        throw new Error('パスワードの有効期限が始まっていません。');
      } else if (endTime < now) {
        throw new Error('パスワードの有効期限が切れています。');
      }
    } else {
      throw new Error('パスワードが存在しません。');
    }
  } catch (e) {
    const api = new ApiGatewayManagementApi({ endpoint: `${event.requestContext.domainName}/${event.requestContext.stage}` });
    await api.postToConnection({
      ConnectionId: event.requestContext.connectionId,
      Data: JSON.stringify({
        message: `${e}`,
      }),
    }).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({}),
    };
  }
  const connections = await dynamodb.scan({ TableName: process.env.DYNAMODB_CONNECTIONS, ProjectionExpression: 'ConnectionId' }).promise();
  await Promise.all(connections.Items.map(async ({ ConnectionId }) => {
    try {
      const params: ApiGatewayManagementApi.Types.PostToConnectionRequest = {
        ConnectionId: ConnectionId,
        Data: event.body,
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
