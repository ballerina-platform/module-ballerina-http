// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;

configurable int maxActiveConnections = -1;
configurable int maxIdleConnections = 100;
configurable decimal waitTime = 30;
configurable int maxActiveStreamsPerConnection = 100;
configurable decimal minEvictableIdleTime = 300;
configurable decimal timeBetweenEvictionRuns = 30;
configurable decimal minIdleTimeInStaleState = 300;
configurable decimal timeBetweenStaleEviction = 30;

# Configurations for managing HTTP client connection pool.
#
# + maxActiveConnections - Max active connections per route(host:port). Default value is -1 which indicates unlimited.
# + maxIdleConnections - Maximum number of idle connections allowed per pool.
# + waitTime - Maximum amount of time (in seconds), the client should wait for an idle connection before it sends an error when the pool is exhausted
# + maxActiveStreamsPerConnection - Maximum active streams per connection. This only applies to HTTP/2. Default value is 100
# + minEvictableIdleTime - Minimum evictable time for an idle connection in seconds. Default value is 5 minutes
# + timeBetweenEvictionRuns - Time between eviction runs in seconds. Default value is 30 seconds
# + minIdleTimeInStaleState - Minimum time in seconds for a connection to be kept open which has received a GOAWAY.
#                             This only applies for HTTP/2. Default value is 5 minutes. If the value is set to -1,
#                             the connection will be closed after all in-flight streams are completed
# + timeBetweenStaleEviction - Time between the connection stale eviction runs in seconds. This only applies for HTTP/2.
#                           Default value is 30 seconds
public type PoolConfiguration record {|
    int maxActiveConnections = maxActiveConnections;
    int maxIdleConnections = maxIdleConnections;
    decimal waitTime = waitTime;
    int maxActiveStreamsPerConnection = maxActiveStreamsPerConnection;
    decimal minEvictableIdleTime = minEvictableIdleTime;
    decimal timeBetweenEvictionRuns = timeBetweenEvictionRuns;
    decimal minIdleTimeInStaleState = minIdleTimeInStaleState;
    decimal timeBetweenStaleEviction = timeBetweenStaleEviction;
|};

//This is a hack to get the global map initialized, without involving locking.
class ConnectionManager {
    public PoolConfiguration & readonly poolConfig = {};
    public isolated function init() {
        self.initGlobalPool(self.poolConfig);
    }

    isolated function initGlobalPool(PoolConfiguration poolConfig) {
        return externInitGlobalPool(poolConfig);
    }
}

isolated function externInitGlobalPool(PoolConfiguration poolConfig) =
@java:Method {
    'class: "io.ballerina.stdlib.http.api.client.endpoint.InitGlobalPool",
    name: "initGlobalPool"
} external;

ConnectionManager connectionManager = new;
final PoolConfiguration & readonly globalHttpClientConnPool = connectionManager.poolConfig;
