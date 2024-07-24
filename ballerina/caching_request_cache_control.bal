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

# Configures the cache control directives for an `http:Request`.
#
# + noCache - Sets the `no-cache` directive
# + noStore - Sets the `no-store` directive
# + noTransform - Sets the `no-transform` directive
# + onlyIfCached - Sets the `only-if-cached` directive
# + maxAge - Sets the `max-age` directive
# + maxStale - Sets the `max-stale` directive
# + minFresh - Sets the `min-fresh` directive
public class RequestCacheControl {

    public boolean noCache = false;
    public boolean noStore = false;
    public boolean noTransform = false;
    public boolean onlyIfCached = false;
    public decimal maxAge = -1;
    public decimal maxStale = -1;
    public decimal minFresh = -1;

    # Builds the cache control directives string from the current `http:RequestCacheControl` configurations.
    #
    # + return - The cache control directives string to be used in the `cache-control` header
    public isolated function buildCacheControlDirectives () returns string {
        string[] directives = [];
        int i = 0;

        if self.noCache {
            directives[i] = NO_CACHE;
            i += 1;
        }

        if self.noStore {
            directives[i] = NO_STORE;
            i += 1;
        }

        if self.noTransform {
            directives[i] = NO_TRANSFORM;
            i += 1;
        }

        if self.onlyIfCached {
            directives[i] = ONLY_IF_CACHED;
            i += 1;
        }

        if self.maxAge >= 0d {
            directives[i] = string `${MAX_AGE}=${decimal:floor(self.maxAge)}`;
            i += 1;
        }

        if self.maxStale == MAX_STALE_ANY_AGE {
            directives[i] = MAX_STALE;
            i += 1;
        } else if self.maxStale >= 0d {
            directives[i] = string `${MAX_STALE}=${decimal:floor(self.maxStale)}`;
            i += 1;
        }

        if self.minFresh >= 0d {
            directives[i] = string `${MIN_FRESH}=${decimal:floor(self.minFresh)}`;
            i += 1;
        }

        return buildCommaSeparatedString(directives);
    }
}

isolated function setRequestCacheControlHeader(Request request) {
    var requestCacheControl = request.cacheControl;
    if requestCacheControl is RequestCacheControl {
        if !request.hasHeader(CACHE_CONTROL) {
            request.setHeader(CACHE_CONTROL, requestCacheControl.buildCacheControlDirectives());
        }
    }
}
