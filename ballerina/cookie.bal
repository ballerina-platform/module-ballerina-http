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

import ballerina/lang.'string as strings;
import ballerina/time;

# The options to be used when initializing the `http:Cookie`.
#
# + path - URI path to which the cookie belongs
# + domain - Host to which the cookie will be sent
# + expires - Maximum lifetime of the cookie represented as the date and time at which the cookie expires
# + maxAge - Maximum lifetime of the cookie represented as the number of seconds until the cookie expires
# + httpOnly - Cookie is sent only to HTTP requests
# + secure - Cookie is sent only to secure channels
# + createdTime - At what time the cookie was created
# + lastAccessedTime - Last-accessed time of the cookie
# + hostOnly - Cookie is sent only to the requested host
public type CookieOptions record {|
    string path?;
    string domain?;
    string expires?;
    int maxAge = 0;
    boolean httpOnly = false;
    boolean secure = false;
    time:Utc createdTime = time:utcNow();
    time:Utc lastAccessedTime = time:utcNow();
    boolean hostOnly = false;
|};

# Represents a Cookie.
# 
# + name - Name of the cookie
# + value - Value of the cookie
# + path - URI path to which the cookie belongs
# + domain - Host to which the cookie will be sent
# + expires - Maximum lifetime of the cookie represented as the date and time at which the cookie expires
# + maxAge - Maximum lifetime of the cookie represented as the number of seconds until the cookie expires
# + httpOnly - Cookie is sent only to HTTP requests
# + secure - Cookie is sent only to secure channels
# + createdTime - At what time the cookie was created
# + lastAccessedTime - Last-accessed time of the cookie
# + hostOnly - Cookie is sent only to the requested host
public readonly class Cookie {

    public string name;
    public string value;
    public string? path;
    public string? domain;
    public string? expires;
    public int maxAge;
    public boolean httpOnly;
    public boolean secure;
    public time:Utc createdTime;
    public time:Utc lastAccessedTime;
    public boolean hostOnly;

    # Initializes the `http:Cookie` object.
    #
    # + name - Name of the `http:Cookie`
    # + value - Value of the `http:Cookie`
    # + options - The options to be used when initializing the `http:Cookie`
    public isolated function init(string name, string value, *CookieOptions options) {
        self.name = name.trim();
        self.value = value.trim();
        string? domainOpt = options?.domain;
        if domainOpt is string {
            string domain = domainOpt.trim().toLowerAscii();
            if domain.startsWith(".") {
                domain = (domain).substring(1, domain.length());
            }
            if domain.endsWith(".") {
                domain = domain.substring(0, domain.length() - 1);
            }
            self.domain = domain;
        } else {
            self.domain = ();
        }
        var path = options?.path;
        if path is string {
            self.path = path.trim();
        } else {
            self.path = ();
        }
        var expiresOpt = options?.expires;
        if expiresOpt is string {
            string expires = expiresOpt.trim();
            time:Utc|error t1 = utcFromString(expires, "yyyy-MM-dd HH:mm:ss");
            if t1 is time:Utc {
                string|error timeString = utcToString(t1, "E, dd MMM yyyy HH:mm:ss");
                if timeString is string {
                    self.expires = timeString + "GMT";
                } else {
                    self.expires = expires;
                }
            } else {
                self.expires = expires;
            }
        } else {
            self.expires = ();
        }
        self.maxAge = options.maxAge;
        self.httpOnly = options.httpOnly;
        self.secure = options.secure;
        self.createdTime = options.createdTime;
        self.lastAccessedTime = options.lastAccessedTime;
        self.hostOnly = options.hostOnly;
    }

    # Checks the persistence of the cookie.
    #
    # + return  - `false` if the cookie will be discarded at the end of the "session" or else `true`.
    public isolated function isPersistent() returns boolean {
        if self.expires is () && self.maxAge == 0 {
            return false;
        }
        return true;
    }

    # Checks the validity of the attributes of the cookie.
    #
    # + return  - `true` if the attributes of the cookie are in the correct format or else an `http:InvalidCookieError`
    public isolated function isValid() returns boolean|InvalidCookieError {
        if self.name == "" {
            return error InvalidCookieError("Invalid name: Name cannot be empty");
        }
        if self.value == "" {
            return error InvalidCookieError("Invalid value: Value cannot be empty");
        }
        var domain = self.domain;
        if domain is string {
            if (domain == "") {
                return error InvalidCookieError("Invalid domain: Domain cannot be empty");
            }
        }
        var path = self.path;
        if path is string {
            if path == "" || !path.startsWith("/") || strings:includes(path, "?") {
                return error InvalidCookieError("Invalid path: Path is not in correct format");
            }
        }
        var expires = self.expires;
        if expires is string && !expires.endsWith("GMT") && !toGmtFormat(expires) {
            return error InvalidCookieError("Invalid time: Expiry-time is not in yyyy-mm-dd hh:mm:ss format");
        }
        if self.maxAge < 0 {
            return error InvalidCookieError("Invalid max-age: Max Age can not be less than zero");
        }
        return true;
    }

    # Gets the Cookie object in its string representation to be used in the ‘Set-Cookie’ header of the response.
    #
    # + return  - The string value of the `http:Cookie`
    public isolated function toStringValue() returns string {
        string setCookieHeaderValue = "";
        var tempName = self.name;
        var tempValue = self.value;
        setCookieHeaderValue = appendNameValuePair(setCookieHeaderValue, tempName, tempValue);
        string? temp = self.domain;
        if temp is string {
            setCookieHeaderValue = appendNameValuePair(setCookieHeaderValue, DOMAIN_ATTRIBUTE, temp);
        }
        temp = self.path;
        if temp is string {
            setCookieHeaderValue = appendNameValuePair(setCookieHeaderValue, PATH_ATTRIBUTE, temp);
        }
        temp = self.expires;
        if temp is string {
            setCookieHeaderValue = appendNameValuePair(setCookieHeaderValue, EXPIRES_ATTRIBUTE, temp);
        }
        if self.maxAge > 0 {
            setCookieHeaderValue = appendNameIntValuePair(setCookieHeaderValue, MAX_AGE_ATTRIBUTE, self.maxAge);
        }
        if self.httpOnly {
            setCookieHeaderValue = appendOnlyName(setCookieHeaderValue, HTTP_ONLY_ATTRIBUTE);
        }
        if self.secure {
            setCookieHeaderValue = appendOnlyName(setCookieHeaderValue, SECURE_ATTRIBUTE);
        }
        setCookieHeaderValue = setCookieHeaderValue.substring(0, setCookieHeaderValue.length() - 2);
        return setCookieHeaderValue;
    }
}

// Converts the cookie's expiry time into the GMT format.
isolated function toGmtFormat(string expires) returns boolean {
    // TODO check this formatter with new time API
    time:Utc|error t1 = utcFromString(expires, "yyyy-MM-dd HH:mm:ss");
    if t1 is time:Utc {
        string|error timeString = utcToString(t1, "E, dd MMM yyyy HH:mm:ss");
        if timeString is string {
            return true;
        }
    }
    return false;
}

const string DOMAIN_ATTRIBUTE = "Domain";
const string PATH_ATTRIBUTE = "Path";
const string EXPIRES_ATTRIBUTE = "Expires";
const string MAX_AGE_ATTRIBUTE = "Max-Age";
const string HTTP_ONLY_ATTRIBUTE = "HttpOnly";
const string SECURE_ATTRIBUTE = "Secure";
const EQUALS = "=";
const SPACE = " ";
const SEMICOLON = ";";

isolated function appendNameValuePair(string setCookieHeaderValue, string name, string value) returns string {
    return setCookieHeaderValue + name + EQUALS + value + SEMICOLON + SPACE;
}

isolated function appendOnlyName(string setCookieHeaderValue, string name) returns string {
    return setCookieHeaderValue + name + SEMICOLON + SPACE;
}

isolated function appendNameIntValuePair(string setCookieHeaderValue, string name, int value) returns string {
    return setCookieHeaderValue + name + EQUALS + value.toString() + SEMICOLON + SPACE;
}
