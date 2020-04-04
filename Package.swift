// swift-tools-version:5.2
//
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

import PackageDescription

let package = Package(
    name: "SmokeDynamoDB",
    platforms: [
        .macOS(.v10_15), .iOS(.v10)
        ],
    products: [
        .library(
            name: "SmokeDynamoDB",
            targets: ["SmokeDynamoDB"]),
    ],
    dependencies: [
        .package(name: "SmokeAWS", url: "https://github.com/amzn/smoke-aws.git", .branch("use_swift_crypto_under_5_2")),
        .package(name: "SmokeHTTP", url: "https://github.com/amzn/smoke-http.git", from: "2.0.0-alpha.8"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", "1.0.0"..<"3.0.0"),
    ],
    targets: [
        .target(
            name: "SmokeDynamoDB", dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "DynamoDBClient", package: "SmokeAWS"),
                .product(name: "SmokeHTTPClient", package: "SmokeHTTP"),
            ]),
        .testTarget(
            name: "SmokeDynamoDBTests", dependencies: [
                .target(name: "SmokeDynamoDB"),
                .product(name: "SmokeHTTPClient", package: "SmokeHTTP"),
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
