// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/time;

isolated function isFreshResponse(Response cachedResponse, boolean isSharedCache) returns @tainted boolean {
    time:Seconds currentAge = getResponseAge(cachedResponse);
    time:Seconds freshnessLifetime = getFreshnessLifetime(cachedResponse, isSharedCache);
    return freshnessLifetime > currentAge;
}

// Based on https://tools.ietf.org/html/rfc7234#section-4.2.1
isolated function getFreshnessLifetime(Response cachedResponse, boolean isSharedCache) returns time:Seconds {
    // TODO: Ensure that duplicate directives are not counted towards freshness lifetime.
    var responseCacheControl = cachedResponse.cacheControl;
    if (responseCacheControl is ResponseCacheControl) {
        if (isSharedCache && responseCacheControl.sMaxAge >= 0d) {
            return <time:Seconds> responseCacheControl.sMaxAge;
        }

        if (responseCacheControl.maxAge >= 0d) {
            return <time:Seconds> responseCacheControl.maxAge;
        }
    }

    // At this point, there should be exactly one Expires header to calculate the freshness lifetime.
    // When adding heuristic calculations, the condition would change to >1.
    string[]|error expiresHeader = cachedResponse.getHeaders(EXPIRES);
    if (expiresHeader is error) {
        return STALE;
    } else {
        if (expiresHeader.length() != 1) {
            return STALE;
        }

        string[]|error dateHeader = cachedResponse.getHeaders(DATE);
        if (dateHeader is error) {
            return STALE;
        } else {
            if (dateHeader.length() != 1) {
                return STALE;
            }

            var tExpiresHeader = utcFromString(expiresHeader[0], RFC_1123_DATE_TIME);
            var tDateHeader = utcFromString(dateHeader[0], RFC_1123_DATE_TIME);
            if (tExpiresHeader is time:Utc && tDateHeader is time:Utc) {
                time:Seconds freshnessLifetime = time:utcDiffSeconds(tExpiresHeader, tDateHeader);
                return freshnessLifetime;
            }

            // TODO: Add heuristic freshness lifetime calculation

            return STALE;
        }
    }
}
