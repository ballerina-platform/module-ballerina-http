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

import ballerina/log;
import ballerina/time;
import ballerina/lang.regexp;

# Represents the cookie store.
#
# + allSessionCookies - Array to store all the session cookies
# + persistentCookieHandler - Persistent cookie handler to manage persistent cookies
public isolated class CookieStore {

    private final Cookie[] allSessionCookies = [];
    private final PersistentCookieHandler? persistentCookieHandler;

    public isolated function init(PersistentCookieHandler? persistentCookieHandler = ()) {
        self.persistentCookieHandler = persistentCookieHandler;
    }

    # Adds a cookie to the cookie store according to the rules in [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.3).
    #
    # + cookie - Cookie to be added
    # + cookieConfig - Configurations associated with the cookies
    # + url - Target service URL
    # + requestPath - Resource path
    # + return - An `http:CookieHandlingError` if there is any error occurred when adding a cookie or else `()`
    public isolated function addCookie(Cookie cookie, CookieConfig cookieConfig, string url, string requestPath) returns CookieHandlingError? {
        if self.getAllCookies().length() == cookieConfig.maxTotalCookieCount {
            return error CookieHandlingError("Number of total cookies in the cookie store can not exceed the maximum amount");
        }

        string domain = getDomain(url);
        if self.getCookiesByDomain(domain).length() == cookieConfig.maxCookiesPerDomain {
            return error CookieHandlingError("Number of total cookies for the domain: " + domain + " in the cookie store can not exceed the maximum amount per domain");
        }

        string path  = getReqPath(url, requestPath);
        int? index = requestPath.indexOf("?");
        if index is int {
            path = requestPath.substring(0, index);
        }

        Cookie? domainValidated = matchDomain(cookie, domain, cookieConfig);
        if domainValidated is () {
            return;
        }
        Cookie? pathValidated = matchPath(domainValidated, path, cookieConfig);
        if pathValidated is () {
            return;
        }
        Cookie? validated = validateExpiresAttribute(pathValidated);
        if validated is () {
            return;
        }
        if !((url.startsWith(HTTP) && validated.httpOnly) || !validated.httpOnly) {
            return;
        }
        lock {
            Cookie? identicalCookie = self.getIdenticalCookie(validated);
            if validated.isPersistent() {
                var persistentCookieHandler = self.persistentCookieHandler;
                if persistentCookieHandler is PersistentCookieHandler {
                    var result = self.addPersistentCookie(identicalCookie, validated, url, persistentCookieHandler);
                    if result is error {
                        return error CookieHandlingError("Error in adding persistent cookies", result);
                    }
                } else if isFirstRequest(self.allSessionCookies, domain) {
                    log:printError("Client is not configured to use persistent cookies. Hence, persistent cookies from "
                                        + domain + " will be discarded.");
                }
            } else {
                var result = self.addSessionCookie(identicalCookie, validated, url);
                if result is error {
                    return error CookieHandlingError("Error in adding session cookie", result);
                }
            }
        }
        return;
    }

    # Adds an array of cookies.
    #
    # + cookiesInResponse - Cookies to be added
    # + cookieConfig - Configurations associated with the cookies
    # + url - Target service URL
    # + requestPath - Resource path
    public isolated function addCookies(Cookie[] cookiesInResponse, CookieConfig cookieConfig, string url, string requestPath) {
        foreach var cookie in cookiesInResponse {
            var result = self.addCookie(cookie, cookieConfig, url, requestPath);
            if result is error {
                log:printError("Error in adding cookies to cookie store: ", 'error = result);
            }
        }
    }

    # Gets the relevant cookies for the given URL and the path according to the rules in [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.4).
    #
    # + url - URL of the request URI
    # + requestPath - Path of the request URI
    # + return - Array of the matched cookies stored in the cookie store
    public isolated function getCookies(string url, string requestPath) returns Cookie[] {
        Cookie[] cookiesToReturn = [];
        string domain = getDomain(url);
        string path  = getReqPath(url, requestPath);
        int? index = requestPath.indexOf("?");
        if index is int {
            path = requestPath.substring(0,index);
        }
        Cookie[] allCookies = self.getAllCookies();
        lock {
            foreach var cookie in allCookies {
                if isExpired(cookie) {
                    continue;
                }
                if !((url.startsWith(HTTPS) && cookie.secure) || cookie.secure == false) {
                    continue;
                }
                if !((url.startsWith(HTTP) && cookie.httpOnly) || cookie.httpOnly == false) {
                    continue;
                }
                if cookie.hostOnly == true {
                    if cookie.domain == domain && checkPath(path, cookie) {
                        cookiesToReturn.push(cookie);
                    }
                } else {
                    var cookieDomain = cookie.domain;
                    if ((cookieDomain is string && domain.endsWith("." + cookieDomain)) || cookie.domain == domain ) && checkPath(path, cookie) {
                        cookiesToReturn.push(cookie);
                    }
                }
            }
            return cookiesToReturn;
        }
    }

    # Gets all the cookies in the cookie store.
    #
    # + return - Array of all the cookie objects
    public isolated function getAllCookies() returns Cookie[] {
        var persistentCookieHandler = self.persistentCookieHandler;
        Cookie[] allCookies = [];
        lock {
            allCookies = self.allSessionCookies.clone();
        }
        if persistentCookieHandler is PersistentCookieHandler {
            var result = persistentCookieHandler.getAllCookies();
            if result is error {
                log:printError("Error in getting persistent cookies: ", 'error = result);
            } else {
                foreach var cookie in result {
                    allCookies.push(cookie);
                }
            }
        }
        return allCookies;
    }

    # Gets all the cookies, which have the given name as the name of the cookie.
    #
    # + cookieName - Name of the cookie
    # + return - Array of all the matched cookie objects
    public isolated function getCookiesByName(string cookieName) returns Cookie[] {
        Cookie[] cookiesToReturn = [];
        Cookie[] allCookies = self.getAllCookies();
        foreach var cookie in allCookies {
            if cookie.name == cookieName {
                cookiesToReturn.push(cookie);
            }
        }
        return cookiesToReturn;
    }

    # Gets all the cookies, which have the given name as the domain of the cookie.
    #
    # + domain - Name of the domain
    # + return - Array of all the matched cookie objects
    public isolated function getCookiesByDomain(string domain) returns Cookie[] {
        Cookie[] cookiesToReturn = [];
        Cookie[] allCookies = self.getAllCookies();
        foreach var cookie in allCookies {
            if cookie.domain == domain {
                cookiesToReturn.push(cookie);
            }
        }
        return cookiesToReturn;
    }

    # Removes a specific cookie.
    #
    # + name - Name of the cookie to be removed
    # + domain - Domain of the cookie to be removed
    # + path - Path of the cookie to be removed
    # + return - An `http:CookieHandlingError` if there is any error occurred during the removal of the cookie or else `()`
    public isolated function removeCookie(string name, string domain, string path) returns CookieHandlingError? {
        lock {
            // Removes the session cookie if it is in the session cookies array, which is matched with the given name, domain, and path.
            int k = 0;
            while k < self.allSessionCookies.length() {
                if name == self.allSessionCookies[k].name && domain == self.allSessionCookies[k].domain && path ==  self.allSessionCookies[k].path {
                    int j = k;
                    while j < self.allSessionCookies.length() - 1 {
                        self.allSessionCookies[j] = self.allSessionCookies[j + 1];
                        j += 1;
                    }
                    _ = self.allSessionCookies.pop();
                    return;
                }
                k += 1;
            }
            // Removes the persistent cookie if it is in the persistent cookie store, which is matched with the given name, domain, and path.
            var persistentCookieHandler = self.persistentCookieHandler;
            if persistentCookieHandler is PersistentCookieHandler {
                return persistentCookieHandler.removeCookie(name, domain, path);
            }
            return error CookieHandlingError("Error in removing cookie: No such cookie to remove");
        }
    }

    # Removes cookies, which match with the given domain.
    #
    # + domain - Domain of the cookie to be removed
    # + return - An `http:CookieHandlingError` if there is any error occurred during the removal of cookies by domain or else `()`
    public isolated function removeCookiesByDomain(string domain) returns CookieHandlingError? {
        lock {
            Cookie[] allCookies = self.getAllCookies();
            foreach var cookie in allCookies {
                if cookie.domain != domain {
                    continue;
                }
                var cookieName = cookie.name;
                var cookiePath = cookie.path;
                if cookiePath is string {
                    var result = self.removeCookie(cookieName, domain, cookiePath);
                    if result is error {
                        return error CookieHandlingError("Error in removing cookies", result);
                    }
                }
            }
        }
        return;
    }

    # Removes all expired cookies.
    #
    # + return - An `http:CookieHandlingError` if there is any error occurred during the removal of expired cookies or else `()`
    public isolated function removeExpiredCookies() returns CookieHandlingError? {
        var persistentCookieHandler = self.persistentCookieHandler;
        if persistentCookieHandler is PersistentCookieHandler {
            var result = persistentCookieHandler.getAllCookies();
            if result is error {
                return error CookieHandlingError("Error in removing expired cookies", result);
            } else {
                lock {
                    foreach var cookie in result {
                        if !isExpired(cookie) {
                            continue;
                        }
                        var cookieName = cookie.name;
                        var cookieDomain = cookie.domain;
                        var cookiePath = cookie.path;
                        if cookieDomain is string && cookiePath is string {
                            var removeResult = persistentCookieHandler.removeCookie(cookieName, cookieDomain, cookiePath);
                            if removeResult is error {
                                return error CookieHandlingError("Error in removing expired cookies", removeResult);
                            }
                        }
                    }
                }
            }
        } else {
            return error CookieHandlingError("No persistent cookie store to remove expired cookies");
        }
        return;
    }

    # Removes all the cookies.
    #
    # + return - An `http:CookieHandlingError` if there is any error occurred during the removal of all the cookies or else `()`
    public isolated function removeAllCookies() returns CookieHandlingError? {
        var persistentCookieHandler = self.persistentCookieHandler;
        lock {
            self.allSessionCookies.removeAll();
            if persistentCookieHandler is PersistentCookieHandler {
                return persistentCookieHandler.removeAllCookies();
            }
        }
        return;
    }

    # Gets the identical cookie for a given cookie if one exists.
    # Identical cookie is the cookie, which has the same name, domain and path as the given cookie.
    #
    # + cookieToCompare - Cookie to be compared
    # + return - Identical cookie if one exists, else `()`
    isolated function getIdenticalCookie(Cookie cookieToCompare) returns Cookie? {
        Cookie[] allCookies = self.getAllCookies();
        int k = 0 ;
        while k < allCookies.length() {
            if cookieToCompare.name == allCookies[k].name && cookieToCompare.domain == allCookies[k].domain
                && cookieToCompare.path ==  allCookies[k].path {
                return allCookies[k];
            }
            k += 1;
        }
        return;
    }

    // Adds a session cookie to the cookie store according to the rules in [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.3 , https://tools.ietf.org/html/rfc6265#section-4.1.2).
    isolated function addSessionCookie(Cookie? identicalCookie, Cookie cookie, string url) returns error? {
        if identicalCookie is Cookie {
            var identicalCookieName = identicalCookie.name;
            var identicalCookieDomain = identicalCookie.domain;
            var identicalCookiePath = identicalCookie.path;
            // Removes the old cookie and adds the new session cookie.
            if ((identicalCookie.httpOnly && url.startsWith(HTTP)) || identicalCookie.httpOnly == false)
                && identicalCookieDomain is string && identicalCookiePath is string {
                var removeResult = self.removeCookie(identicalCookieName, identicalCookieDomain, identicalCookiePath);
                if removeResult is error {
                    return removeResult;
                }
                lock {
                    self.allSessionCookies.push(getClone(cookie, identicalCookie.createdTime, time:utcNow()));
                }
            }
        } else {
            // Adds the session cookie.
            lock {
                self.allSessionCookies.push(getClone(cookie, time:utcNow(), time:utcNow()));
            }
        }
        return;
    }

    // Adds a persistent cookie to the cookie store according to the rules in [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.3 , https://tools.ietf.org/html/rfc6265#section-4.1.2).
    isolated function addPersistentCookie(Cookie? identicalCookie, Cookie cookie, string url, PersistentCookieHandler persistentCookieHandler) returns error? {
        if identicalCookie is Cookie {
            string identicalCookieName = identicalCookie.name;
            var identicalCookieDomain = identicalCookie.domain;
            var identicalCookiePath = identicalCookie.path;
            if isExpired(cookie) && identicalCookieDomain is string && identicalCookiePath is string {
                return self.removeCookie(identicalCookieName, identicalCookieDomain, identicalCookiePath);
            } else {
                // Removes the old cookie and adds the new persistent cookie.
                if ((identicalCookie.httpOnly && url.startsWith(HTTP)) || identicalCookie.httpOnly == false)
                    && identicalCookieDomain is string && identicalCookiePath is string {
                    var removeResult = self.removeCookie(identicalCookieName, identicalCookieDomain, identicalCookiePath);
                    if removeResult is error {
                        return removeResult;
                    }
                    Cookie newCookie = getClone(cookie, identicalCookie.createdTime, time:utcNow());
                    return persistentCookieHandler.storeCookie(newCookie);
                }
            }
        } else {
            // If cookie is not expired, adds that cookie.
            if !isExpired(cookie) {
                Cookie newCookie = getClone(cookie, time:utcNow(), time:utcNow());
                return persistentCookieHandler.storeCookie(newCookie);
            }
        }
        return;
    }
}

const string HTTP = "http";
const string HTTPS = "https";
const string URL_TYPE_1 = "https://www.";
const string URL_TYPE_2 = "http://www.";
const string URL_TYPE_3 = "http://";
const string URL_TYPE_4 = "https://";

final regexp:RegExp SLASH_REGEX = re `/`;

// Extracts domain name from the request URL.
isolated function getDomain(string url) returns string {
    string domain = url;
    if url.startsWith(URL_TYPE_1) {
        domain = SLASH_REGEX.split(url.substring(URL_TYPE_1.length(), url.length()))[0];
    } else if url.startsWith(URL_TYPE_2) {
        domain = SLASH_REGEX.split(url.substring(URL_TYPE_2.length(), url.length()))[0];
    } else if url.startsWith(URL_TYPE_3) {
        domain = SLASH_REGEX.split(url.substring(URL_TYPE_3.length(), url.length()))[0];
    } else if url.startsWith(URL_TYPE_4) {
        domain = SLASH_REGEX.split(url.substring(URL_TYPE_4.length(), url.length()))[0];
    }
    return domain.toLowerAscii();
}

// Construct the request path from client url and the path from client method invocation.
isolated function getReqPath(string url, string path) returns string {
    regexp:Groups? groups = re `^(?:https?://)?[^/]+(/.*)?$`.findGroups(url);
    if groups is () || groups.length() == 1 || groups[1] is () {
        return path;
    }
    return (<regexp:Span>groups[1]).substring() + path;
}


// Returns true if the cookie domain matches with the request domain according to [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.1.3).
isolated function matchDomain(Cookie cookie, string domain, CookieConfig cookieConfig) returns Cookie? {
    var cookieDomain = cookie.domain;
    if cookieDomain == () {
        return getCloneWithDomainAndHostOnly(cookie, domain, true);
    } else {
        Cookie newCookie = getCloneWithHostOnly(cookie, false);
        if !cookieConfig.blockThirdPartyCookies {
            return newCookie;
        }
        Cookie updatedCookie = getCloneWithDomainAndHostOnly(newCookie, cookieDomain, false);
        if cookieDomain == domain || domain.endsWith("." + cookieDomain) {
            return updatedCookie;
        }
        return;
    }
}

// Returns true if the cookie path matches the request path according to [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.1.4).
isolated function matchPath(Cookie cookie, string path, CookieConfig cookieConfig) returns Cookie? {
    if cookie.path == () {
        return getCloneWithPath(cookie, path);
    }
    if !cookieConfig.blockThirdPartyCookies {
        return cookie;
    }
    if checkPath(path, cookie) {
        return cookie;
    }
    return;
}

isolated function checkPath(string path, Cookie cookie) returns boolean {
    if cookie.path == path {
        return true;
    }
    var cookiePath = cookie.path;
    if cookiePath is string && path.startsWith(cookiePath) && cookiePath.endsWith("/") {
        return true;
    }
    if cookiePath is string && path.startsWith(cookiePath) && path[cookiePath.length()] == "/" {
        return true;
    }
    return false;
}

// Returns true if the cookie expires attribute value is valid according to [RFC-6265](https://tools.ietf.org/html/rfc6265#section-5.1.1).
isolated function validateExpiresAttribute(Cookie cookie) returns Cookie? {
    var expiryTime = cookie.expires;
    if expiryTime is () {
         return cookie;
    }
    time:Utc|error t1 = utcFromString(expiryTime.substring(0, expiryTime.length() - 4), "E, dd MMM yyyy HH:mm:ss");
    if t1 is time:Utc {
        time:Civil civil = time:utcToCivil(t1);
        int year = civil.year;
        if year <= 69 && year >= 0 {
            // Adds 2000 years which is 63072000000 seconds
            time:Utc tmAdd = time:utcAddSeconds(t1, 63072000000);
            string|error timeString = utcToString(tmAdd, "E, dd MMM yyyy HH:mm:ss");
            if timeString is string {
                return getCloneWithExpiresAndMaxAge(cookie, timeString + "GMT", cookie.maxAge);
            }
            return;
        }
        return cookie;
    }
    return;
}

// Checks whether the user has requested a particular domain or a sub-domain of it previously or not.
isolated function isFirstRequest(Cookie[] allSessionCookies, string domain) returns boolean {
    foreach var cookie in allSessionCookies {
       var cookieDomain = cookie.domain;
       if ((cookieDomain is string && (domain.endsWith("." + cookieDomain) || cookieDomain.endsWith("." + domain))) || cookie.domain == domain ) {
           return false;
       }
    }
    return true;
}

// Returns true if the cookie is expired according to the rules in [RFC-6265](https://tools.ietf.org/html/rfc6265#section-4.1.2.2).
isolated function isExpired(Cookie cookie) returns boolean {
    if cookie.maxAge > 0 {
        time:Utc expTime = time:utcAddSeconds(cookie.createdTime, <time:Seconds> cookie.maxAge);
        time:Utc curTime = time:utcNow();
        return (time:utcDiffSeconds(expTime, curTime) < 0d);
    }
    var expiryTime = cookie.expires;
    if expiryTime is string {
        time:Utc|error cookieExpires = utcFromString(expiryTime.substring(0, expiryTime.length() - 4), "E, dd MMM yyyy HH:mm:ss");
        time:Utc curTime = time:utcNow();
        if (cookieExpires is time:Utc) && (time:utcDiffSeconds(cookieExpires, curTime) < 0d) {
            return true;
        }
    }
    return false;
}
