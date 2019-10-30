// Copyright 2018-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
//  AWSDynamoDBCompositePrimaryKeyTable.swift
//  SmokeDynamoDB
//

import Foundation
import LoggerAPI
import DynamoDBClient
import DynamoDBModel
import SmokeAWSCore
import SmokeHTTPClient

public class AWSDynamoDBCompositePrimaryKeyTable: DynamoDBCompositePrimaryKeyTable {
    internal let dynamodb: AWSDynamoDBClient
    internal let targetTableName: String

    static internal let dynamodbEncoder = DynamoDBEncoder()
    static internal let dynamodbDecoder = DynamoDBDecoder()
    static internal let jsonEncoder = JSONEncoder()
    static internal let jsonDecoder = JSONDecoder()

    internal let defaultPaginationLimit = 100

    internal class QueryPaginationResults<AttributesType: PrimaryKeyAttributes, PossibleTypes: PossibleItemTypes> {
        var items: [PolymorphicDatabaseItem<AttributesType, PossibleTypes>] = []
        var exclusiveStartKey: String?
    }

    public init(accessKeyId: String, secretAccessKey: String,
                region: AWSRegion, endpointHostName: String,
                tableName: String,
                eventLoopProvider: HTTPClient.EventLoopProvider = .spawnNewThreads) {
        let staticCredentials = StaticCredentials(accessKeyId: accessKeyId,
                                                  secretAccessKey: secretAccessKey,
                                                  sessionToken: nil)

        self.dynamodb = AWSDynamoDBClient(credentialsProvider: staticCredentials,
                                          awsRegion: region,
                                          endpointHostName: endpointHostName,
                                          eventLoopProvider: eventLoopProvider)
        self.targetTableName = tableName

        Log.info("AWSDynamoDBTable created with region '\(region)' and hostname: '\(endpointHostName)'")
    }

    public init(credentialsProvider: CredentialsProvider,
                region: AWSRegion, endpointHostName: String,
                tableName: String,
                eventLoopProvider: HTTPClient.EventLoopProvider = .spawnNewThreads) {
        self.dynamodb = AWSDynamoDBClient(credentialsProvider: credentialsProvider,
                                          awsRegion: region,
                                          endpointHostName: endpointHostName,
                                          eventLoopProvider: eventLoopProvider)
        self.targetTableName = tableName

        Log.info("AWSDynamoDBTable created with region '\(region)' and hostname: '\(endpointHostName)'")
    }

    /**
     Gracefully shuts down the client behind this table. This function is idempotent and
     will handle being called multiple times.
     */
    public func close() {
        dynamodb.close()
    }

    /**
     Waits for the client behind this table to be closed. If close() is not called,
     this will block forever.
     */
    public func wait() {
        dynamodb.wait()
    }

    internal func getInputForInsert<AttributesType, ItemType>(_ item: TypedDatabaseItem<AttributesType, ItemType>) throws
        -> DynamoDBModel.PutItemInput {
            let attributes = try getAttributes(forItem: item)

            let expressionAttributeNames = ["#pk": AttributesType.partitionKeyAttributeName, "#sk": AttributesType.sortKeyAttributeName]
            let conditionExpression = "attribute_not_exists (#pk) AND attribute_not_exists (#sk)"

            return DynamoDBModel.PutItemInput(conditionExpression: conditionExpression,
                                              expressionAttributeNames: expressionAttributeNames,
                                              item: attributes,
                                              tableName: targetTableName)
    }

    internal func getInputForUpdateItem<AttributesType, ItemType>(
            newItem: TypedDatabaseItem<AttributesType, ItemType>,
            existingItem: TypedDatabaseItem<AttributesType, ItemType>) throws -> DynamoDBModel.PutItemInput {
        let attributes = try getAttributes(forItem: newItem)

        let expressionAttributeNames = ["#rowversion": RowStatus.CodingKeys.rowVersion.stringValue]
        let expressionAttributeValues = [":versionnumber": DynamoDBModel.AttributeValue(N: String(existingItem.rowStatus.rowVersion))]

        let conditionExpression = "#rowversion = :versionnumber"

        return DynamoDBModel.PutItemInput(conditionExpression: conditionExpression,
                                                      expressionAttributeNames: expressionAttributeNames,
                                                      expressionAttributeValues: expressionAttributeValues,
                                                      item: attributes,
                                                      tableName: targetTableName)
    }

    internal func getAttributes<AttributesType, ItemType>(forItem item: TypedDatabaseItem<AttributesType, ItemType>) throws
        -> [String: DynamoDBModel.AttributeValue] {
            let attributeValue = try AWSDynamoDBCompositePrimaryKeyTable.dynamodbEncoder.encode(item)

            let attributes: [String: DynamoDBModel.AttributeValue]
            if let itemAttributes = attributeValue.M {
                attributes = itemAttributes
            } else {
                throw SmokeDynamoDBError.databaseError(reason: "Expected a map.")
            }

            return attributes
    }

    internal func getInputForGetItem<AttributesType>(forKey key: CompositePrimaryKey<AttributesType>) throws -> DynamoDBModel.GetItemInput {
        let attributeValue = try AWSDynamoDBCompositePrimaryKeyTable.dynamodbEncoder.encode(key)

        if let keyAttributes = attributeValue.M {
            return DynamoDBModel.GetItemInput(consistentRead: true,
                                              key: keyAttributes,
                                              tableName: targetTableName)
        } else {
            throw SmokeDynamoDBError.databaseError(reason: "Expected a structure.")
        }
    }

    internal func getInputForDeleteItem<AttributesType>(forKey key: CompositePrimaryKey<AttributesType>) throws -> DynamoDBModel.DeleteItemInput {
        let attributeValue = try AWSDynamoDBCompositePrimaryKeyTable.dynamodbEncoder.encode(key)

        if let keyAttributes = attributeValue.M {
            return DynamoDBModel.DeleteItemInput(key: keyAttributes,
                                                 tableName: targetTableName)
        } else {
            throw SmokeDynamoDBError.databaseError(reason: "Expected a structure.")
        }
    }
}