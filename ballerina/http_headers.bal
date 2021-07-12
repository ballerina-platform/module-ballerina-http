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

# Represents the headers of the inbound request.
public class Headers {

    private Request? request = ();

    isolated function getRequest() returns Request {
        var req = self.request;
        if (req is Request) {
            return req;
        }
        panic error GenericListenerError("Request is not initialized to retrieve headers");
    }

    # Checks whether the requested header key exists in the header map.
    #
    # + headerName - The header name
    # + return - `true` if the specified header key exists
    public isolated function hasHeader(string headerName) returns boolean {
        return self.getRequest().hasHeader(headerName);
    }

    # Returns the value of the specified header. If the specified header key maps to multiple values, the first of
    # these values is returned.
    #
    # + headerName - The header name
    # + return - The first header value for the specified header name or the `HeaderNotFoundError` if the header is not
    #            found.
    public isolated function getHeader(string headerName) returns  string|HeaderNotFoundError {
        return self.getRequest().getHeader(headerName);
    }

    # Gets all the header values to which the specified header key maps to.
    #
    # + headerName - The header name
    # + return - The header values the specified header key maps to or the `HeaderNotFoundError` if the header is not
    #            found.
    public isolated function getHeaders(string headerName) returns  string[]|HeaderNotFoundError {
        return self.getRequest().getHeaders(headerName);
    }

    # Gets all the names of the headers of the request.
    #
    # + return - An array of all the header names
    public isolated function getHeaderNames() returns  string[] {
        return self.getRequest().getHeaderNames();
    }
}

// Please maintain alphabetical order when adding new header names
# HTTP header key `age`. Gives the current age of a cached HTTP response. 
public const string AGE = "age";

# HTTP header key `authorization` 
public const string AUTHORIZATION = "authorization";

# HTTP header key `cache-control`. Specifies the cache control directives required for the function of HTTP caches.
public const string CACHE_CONTROL = "cache-control";

# HTTP header key `content-length`. Specifies the size of the response body in bytes. 
public const string CONTENT_LENGTH = "content-length";

# HTTP header key `content-type`. Specifies the type of the message payload. 
public const string CONTENT_TYPE = "content-type";

# HTTP header key `date`. The timestamp at the time the response was generated/received. 
public const string DATE = "date";

# HTTP header key `etag`. A finger print for a resource which is used by HTTP caches to identify whether a
# resource representation has changed.
public const string ETAG = "etag";

# HTTP header key `expect`. Specifies expectations to be fulfilled by the server. 
public const string EXPECT = "expect";

# HTTP header key `expires`. Specifies the time at which the response becomes stale. 
public const string EXPIRES = "expires";

# HTTP header key `if-match` 
public const string IF_MATCH = "if-match";

# HTTP header key `if-modified-since`. Used when validating (with the origin server) whether a cached response
# is still valid. If the representation of the resource has modified since the timestamp in this field, a
# 304 response is returned.
public const string IF_MODIFIED_SINCE = "if-modified-since";

# HTTP header key `if-none-match`. Used when validating (with the origin server) whether a cached response is
# still valid. If the ETag provided in this field matches the representation of the requested resource, a
# 304 response is returned.
public const string IF_NONE_MATCH = "if-none-match";

# HTTP header key `if-range` 
public const string IF_RANGE = "if-range";

# HTTP header key `if-unmodified-since` 
public const string IF_UNMODIFIED_SINCE = "if-unmodified-since";

# HTTP header key `last-modified`. The time at which the resource was last modified. 
public const string LAST_MODIFIED = "last-modified";

# HTTP header key `location`. Indicates the URL to redirect a request to. 
public const string LOCATION = "location";

# HTTP header key `pragma`. Used in dealing with HTTP 1.0 caches which do not understand the `cache-control` header.
public const string PRAGMA = "pragma";

# HTTP header key `proxy-authorization`. Contains the credentials to authenticate a user agent to a proxy serve.
public const string PROXY_AUTHORIZATION = "proxy-authorization";

# HTTP header key `server`. Specifies the details of the origin server.
public const string SERVER = "server";

# HTTP header key `warning`. Specifies warnings generated when serving stale responses from HTTP caches. 
public const string WARNING = "warning";

# HTTP header key `transfer-encoding`. Specifies what type of transformation has been applied to entity body. 
public const string TRANSFER_ENCODING = "transfer-encoding";

# HTTP header key `connection`. Allows the sender to specify options that are desired for that particular connection.
public const string CONNECTION = "connection";

# HTTP header key `upgrade`. Allows the client to specify what additional communication protocols it supports and
# would like to use, if the server finds it appropriate to switch protocols.
public const string UPGRADE = "upgrade";
