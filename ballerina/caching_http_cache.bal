// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/cache;
import ballerina/log;

# Implements a cache for storing HTTP responses. This cache complies with the caching policy set when configuring
# HTTP caching in the HTTP client endpoint.
#
# + cache - The underlying cache used for storing HTTP responses
# + policy - Gives the user some control over the caching behaviour. By default, this is set to
#            `CACHE_CONTROL_AND_VALIDATORS`. The default behaviour is to allow caching only when the `cache-control`
#            header and either the `etag` or `last-modified` header are present.
# + isShared - Specifies whether the HTTP caching layer should behave as a public cache or a private cache
public isolated class HttpCache {

    final cache:Cache cache;
    private final CachingPolicy policy;
    private final boolean isShared;

    # Creates the HTTP cache.
    #
    # + cacheConfig - The configurations for the HTTP cache
    public isolated function init(CacheConfig cacheConfig) {
        cache:CacheConfig config = {
            capacity: cacheConfig.capacity,
            evictionFactor: cacheConfig.evictionFactor
        };
        self.cache = new cache:Cache(config);
        self.policy = cacheConfig.policy;
        self.isShared = cacheConfig.isShared;
    }

    isolated function isAllowedToCache(Response response) returns boolean {
        if self.policy == CACHE_CONTROL_AND_VALIDATORS {
            return response.hasHeader(CACHE_CONTROL) && (response.hasHeader(ETAG) || response.hasHeader(LAST_MODIFIED));
        }

        return true;
    }

    isolated function put(string key, RequestCacheControl? requestCacheControl, Response inboundResponse) {
        if self.isNonCacheableResponse(requestCacheControl, inboundResponse.cacheControl) {
            return;
        }

        if self.isCacheableResponse(inboundResponse) {
            // IMPT: The call to getBinaryPayload() builds the payload from the stream. If this is not done, the stream
            // will be read by the client and the response will be after the first cache hit.
            byte[]|error binaryPayload = inboundResponse.getBinaryPayload();
            if binaryPayload is error {
                log:printDebug("Error building the payload in HTTP caching: " + binaryPayload.message());
            }
            log:printDebug("Adding new cache entry for: " + key);
            addEntry(self.cache, key, inboundResponse);
        }
    }

    // TODO: Need to consider https://tools.ietf.org/html/rfc7234#section-3.2 as well here
    private isolated function isNonCacheableResponse(RequestCacheControl? reqCC, ResponseCacheControl? resCC) returns boolean {
        if resCC is ResponseCacheControl {
            if resCC.noStore || (self.isShared && resCC.isPrivate) {
                return true;
            }
        }

        return (reqCC is RequestCacheControl) && reqCC.noStore;
    }

    // Based on https://tools.ietf.org/html/rfc7234#page-6
    // TODO: Consider cache control extensions as well here
    private isolated function isCacheableResponse(Response inboundResp) returns boolean {
        ResponseCacheControl? respCC = inboundResp.cacheControl;
        boolean allowedByCacheControl = false;

        if respCC is ResponseCacheControl {
            if respCC.maxAge >= 0d || (self.isShared && (respCC.sMaxAge >= 0d)) || !respCC.isPrivate {
                allowedByCacheControl = true;
            }
        }

        return allowedByCacheControl || inboundResp.hasHeader(EXPIRES) || isCacheableStatusCode(inboundResp.statusCode);
    }

    isolated function hasKey(string key) returns boolean {
        return self.cache.hasKey(key);
    }

    isolated function get(string key) returns any|error {
        return self.cache.get(key);
    }

    isolated function getAll(string key) returns Response[]|() {
        var cacheEntry = trap <Response[]> checkpanic self.cache.get(key);
        if cacheEntry is Response[] {
            return cacheEntry;
        }
        return ();
    }

    isolated function getAllByETag(string key, string etag) returns Response[] {
        Response[] cachedResponses = [];
        Response[] matchingResponses = [];
        int i = 0;

        var responses = self.getAll(key);
        if responses is Response[] {
            cachedResponses = responses;
        }

        foreach var cachedResp in cachedResponses {
            string|error headerValue = cachedResp.getHeader(ETAG);
            if headerValue is string && headerValue == etag && !etag.startsWith(WEAK_VALIDATOR_TAG) {
                matchingResponses[i] = cachedResp;
                i = i + 1;
            }
        }

        return matchingResponses;
    }

    isolated function getAllByWeakETag(string key, string etag) returns Response[] {
        Response[] cachedResponses = [];
        Response[] matchingResponses = [];
        int i = 0;

        var responses = self.getAll(key);
        if responses is Response[] {
            cachedResponses = responses;
        }

        foreach var cachedResp in cachedResponses {
            string|error etagHeader = cachedResp.getHeader(ETAG);
            if etagHeader is string {
                if weakValidatorEquals(etag, etagHeader) {
                    matchingResponses[i] = cachedResp;
                    i = i + 1;
                }

            }
        }

        return matchingResponses;
    }

    isolated function remove(string key) {
        cache:Error? result = self.cache.invalidate(key);
        if result is cache:Error {
            log:printDebug("Failed to remove the key: " + key + " from the HTTP cache.");
        }
    }
}

isolated function isCacheableStatusCode(int statusCode) returns boolean {
    return statusCode == STATUS_OK || statusCode == STATUS_NON_AUTHORITATIVE_INFORMATION ||
           statusCode == STATUS_NO_CONTENT || statusCode == STATUS_PARTIAL_CONTENT ||
           statusCode == STATUS_MULTIPLE_CHOICES || statusCode == STATUS_MOVED_PERMANENTLY ||
           statusCode == STATUS_NOT_FOUND || statusCode == STATUS_METHOD_NOT_ALLOWED ||
           statusCode == STATUS_GONE || statusCode == STATUS_URI_TOO_LONG ||
           statusCode == STATUS_NOT_IMPLEMENTED;
}

isolated function addEntry(cache:Cache cache, string key, Response inboundResponse) {
    if cache.hasKey(key) {
        Response[] existingResponses = <Response[]> checkpanic cache.get(key);
        existingResponses.push(inboundResponse);
    } else {
        Response[] cachedResponses = [inboundResponse];
        cache:Error? result = cache.put(key, cachedResponses);
        if result is cache:Error {
            log:printDebug("Failed to add cached response with the key: " + key + " to the HTTP cache.");
        }
    }
}

isolated function weakValidatorEquals(string etag1, string etag2) returns boolean {
    string validatorPortion1 = etag1.startsWith(WEAK_VALIDATOR_TAG) ? etag1.substring(2, etag1.length()) : etag1;
    string validatorPortion2 = etag2.startsWith(WEAK_VALIDATOR_TAG) ? etag2.substring(2, etag2.length()) : etag2;

    return validatorPortion1 == validatorPortion2;
}

isolated function getCacheKey(string httpMethod, string url) returns string {
    return string `${httpMethod.toUpperAscii()} ${url}`;
}
