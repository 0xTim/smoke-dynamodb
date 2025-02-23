// Copyright 2018-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
//  AWSDynamoDBCompositePrimaryKeysProjectionGenerator.swift
//  SmokeDynamoDB
//

import Foundation
import Logging
import DynamoDBClient
import DynamoDBModel
import SmokeAWSCore
import SmokeAWSHttp
import SmokeHTTPClient
import AsyncHTTPClient
import NIO

public class AWSDynamoDBCompositePrimaryKeysProjectionGenerator {
    internal let dynamodbGenerator: _AWSDynamoDBClientGenerator
    internal let targetTableName: String

    public init(accessKeyId: String, secretAccessKey: String,
                region: AWSRegion,
                endpointHostName: String, endpointPort: Int = 443,
                requiresTLS: Bool? = nil, tableName: String,
                connectionTimeoutSeconds: Int64 = 10,
                retryConfiguration: HTTPClientRetryConfiguration = .default,
                eventLoopProvider: HTTPClient.EventLoopGroupProvider = .createNew,
                reportingConfiguration: SmokeAWSCore.SmokeAWSClientReportingConfiguration<DynamoDBModel.DynamoDBModelOperations>
                    = SmokeAWSClientReportingConfiguration<DynamoDBModelOperations>()) {
        let staticCredentials = StaticCredentials(accessKeyId: accessKeyId,
                                                  secretAccessKey: secretAccessKey,
                                                  sessionToken: nil)

        self.dynamodbGenerator = _AWSDynamoDBClientGenerator(credentialsProvider: staticCredentials,
                                                             awsRegion: region,
                                                             endpointHostName: endpointHostName,
                                                             endpointPort: endpointPort, requiresTLS: requiresTLS,
                                                             connectionTimeoutSeconds: connectionTimeoutSeconds,
                                                             retryConfiguration: retryConfiguration,
                                                             eventLoopProvider: eventLoopProvider,
                                                             reportingConfiguration: reportingConfiguration)
        self.targetTableName = tableName
    }

    public init(credentialsProvider: CredentialsProvider,
                region: AWSRegion,
                endpointHostName: String, endpointPort: Int = 443,
                requiresTLS: Bool? = nil, tableName: String,
                connectionTimeoutSeconds: Int64 = 10,
                retryConfiguration: HTTPClientRetryConfiguration = .default,
                eventLoopProvider: HTTPClient.EventLoopGroupProvider = .createNew,
                reportingConfiguration: SmokeAWSCore.SmokeAWSClientReportingConfiguration<DynamoDBModel.DynamoDBModelOperations>
                    = SmokeAWSClientReportingConfiguration<DynamoDBModelOperations>()) {
        self.dynamodbGenerator = _AWSDynamoDBClientGenerator(credentialsProvider: credentialsProvider,
                                                             awsRegion: region,
                                                             endpointHostName: endpointHostName,
                                                             endpointPort: endpointPort, requiresTLS: requiresTLS,
                                                             connectionTimeoutSeconds: connectionTimeoutSeconds,
                                                             retryConfiguration: retryConfiguration,
                                                             eventLoopProvider: eventLoopProvider,
                                                             reportingConfiguration: reportingConfiguration)
        self.targetTableName = tableName
    }

    /**
     Gracefully shuts down the client behind this table. This function is idempotent and
     will handle being called multiple times.
     */
    public func close() throws {
        try dynamodbGenerator.close()
    }
    
    public func with<NewInvocationReportingType: HTTPClientCoreInvocationReporting>(
            reporting: NewInvocationReportingType) -> AWSDynamoDBCompositePrimaryKeysProjection<NewInvocationReportingType> {
        return AWSDynamoDBCompositePrimaryKeysProjection<NewInvocationReportingType>(
            dynamodb: self.dynamodbGenerator.with(reporting: reporting),
            targetTableName: self.targetTableName,
            logger: reporting.logger)
    }
    
    public func with<NewTraceContextType: InvocationTraceContext>(
            logger: Logging.Logger,
            internalRequestId: String = "none",
            traceContext: NewTraceContextType,
            eventLoop: EventLoop? = nil) -> AWSDynamoDBCompositePrimaryKeysProjection<StandardHTTPClientCoreInvocationReporting<NewTraceContextType>> {
        let reporting = StandardHTTPClientCoreInvocationReporting(
            logger: logger,
            internalRequestId: internalRequestId,
            traceContext: traceContext,
            eventLoop: eventLoop)

        return with(reporting: reporting)
    }

    public func with(
            logger: Logging.Logger,
            internalRequestId: String = "none",
            eventLoop: EventLoop? = nil) -> AWSDynamoDBCompositePrimaryKeysProjection<StandardHTTPClientCoreInvocationReporting<AWSClientInvocationTraceContext>> {
        let reporting = StandardHTTPClientCoreInvocationReporting(
            logger: logger,
            internalRequestId: internalRequestId,
            traceContext: AWSClientInvocationTraceContext(),
            eventLoop: eventLoop)

        return with(reporting: reporting)
    }
}
