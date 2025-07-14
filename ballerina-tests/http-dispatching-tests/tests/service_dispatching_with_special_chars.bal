// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

import ballerina/http;
import ballerina/test;
import ballerina/url;

const DISPATCH_WITH_SPECIAL_CHARS_PORT = 9090;

listener http:Listener dispatchWithSpecialCharsListener = new (DISPATCH_WITH_SPECIAL_CHARS_PORT);
final http:Client dispatchWithSpecialCharsClient = check new (string `http://localhost:${DISPATCH_WITH_SPECIAL_CHARS_PORT}`);

service /test\$base\&path on dispatchWithSpecialCharsListener {

    resource function get base() returns string {
        return "base";
    }

    resource function get \$path\.new() returns string {
        return "new";
    }

    resource function get path\!with\/slash() returns string {
        return "with slash";
    }

    resource function get path\*with\%percentage()returns string {
        return "with percentage";
    }

    resource function get path\$() returns string {
        return "with dollar";
    }
}

@test:Config
function testBasePathWithSpecialCharsUsingRemoteFunctions() returns error? {
    string response = check dispatchWithSpecialCharsClient->get("/test$base&path/base");
    test:assertEquals(response, "base");

    response = check dispatchWithSpecialCharsClient->get("/test%24base%26path/base");
    test:assertEquals(response, "base");

    response = check dispatchWithSpecialCharsClient->get("/test$base%26path/base");
    test:assertEquals(response, "base");

    response = check dispatchWithSpecialCharsClient->get("/test%24base&path/base");
    test:assertEquals(response, "base");
}

@test:Config
function testBasePathWithSpecialCharsUsingResourceFunctions() returns error? {
    string response = check dispatchWithSpecialCharsClient->/test\$base\&path/base;
    test:assertEquals(response, "base");

    response = check dispatchWithSpecialCharsClient->/["test%24base%26path"]/base;
    test:assertEquals(response, "base");

    response = check dispatchWithSpecialCharsClient->/test\$base\%26path/base;
    test:assertEquals(response, "base");

    response = check dispatchWithSpecialCharsClient->/["test%24base&path"]/base;
    test:assertEquals(response, "base");
}

@test:Config
function testPathWithSpecialChars() returns error? {
    string response = check dispatchWithSpecialCharsClient->get("/test$base&path/$path.new");
    test:assertEquals(response, "new");

    response = check dispatchWithSpecialCharsClient->/["test%24base%26path"]/\$path\.new;
    test:assertEquals(response, "new");

    response = check dispatchWithSpecialCharsClient->/test\$base\&path/\%24path\.new;
    test:assertEquals(response, "new");

    response = check dispatchWithSpecialCharsClient->get("/test%24base&path/%24path.new");
    test:assertEquals(response, "new");

    response = check dispatchWithSpecialCharsClient->get("/test$base&path/path$");
    test:assertEquals(response, "with dollar");

    response = check dispatchWithSpecialCharsClient->/["test$base%26path"]/path\%24;
    test:assertEquals(response, "with dollar");
}

@test:Config
function testPathWithSpecialCharsIncludingSlash() returns error? {
    string response = check dispatchWithSpecialCharsClient->get("/test$base&path/path!with%2Fslash");
    test:assertEquals(response, "with slash");

    response = check dispatchWithSpecialCharsClient->/["test%24base%26path"]/path\!with\%2Fslash;
    test:assertEquals(response, "with slash");

    response = check dispatchWithSpecialCharsClient->/test\$base\&path/path\!with\%2Fslash;
    test:assertEquals(response, "with slash");

    response = check dispatchWithSpecialCharsClient->get("/test%24base&path/path!with%2Fslash");
    test:assertEquals(response, "with slash");
}

@test:Config
function testPathWithSpecialCharsIncludingSlashNegative() returns error? {
    http:Response response = check dispatchWithSpecialCharsClient->get("/test$base&path/path!with/slash");
    test:assertEquals(response.statusCode, 404);

    response = check dispatchWithSpecialCharsClient->/["test%24base%26path"]/path\!with/slash;
    test:assertEquals(response.statusCode, 404);

    response = check dispatchWithSpecialCharsClient->/test\$base\&path/path\!with\/slash;
    test:assertEquals(response.statusCode, 404);
}

@test:Config
function testPathWithSpecialCharsIncludingPercentage() returns error? {
    string response = check dispatchWithSpecialCharsClient->get("/test$base&path/path*with%25percentage");
    test:assertEquals(response, "with percentage");

    response = check dispatchWithSpecialCharsClient->/["test%24base%26path"]/path\*with\%25percentage;
    test:assertEquals(response, "with percentage");

    response = check dispatchWithSpecialCharsClient->/test\$base\&path/path\*with\%25percentage;
    test:assertEquals(response, "with percentage");

    response = check dispatchWithSpecialCharsClient->get("/test%24base&path/path*with%25percentage");
    test:assertEquals(response, "with percentage");
}

@test:Config
function testPathWithSpecialCharsIncludingPercentageNegative() returns error? {
    http:Response response = check dispatchWithSpecialCharsClient->get("/test$base&path/path*with%percentage");
    test:assertEquals(response.statusCode, 404);

    response = check dispatchWithSpecialCharsClient->/["test%24base%26path"]/path\*with\%percentage;
    test:assertEquals(response.statusCode, 404);

    response = check dispatchWithSpecialCharsClient->/test\$base\&path/path\*with\%percentage;
    test:assertEquals(response.statusCode, 404);

    response = check dispatchWithSpecialCharsClient->get("/test%2base&path/path*with/percentage");
    test:assertEquals(response.statusCode, 404);

    response = check dispatchWithSpecialCharsClient->get("/test%24base&path/path%2");
    test:assertEquals(response.statusCode, 404);
}

const int UNICODE_CHAR_PORT = 9091;

listener http:Listener unicodeCharListener = new (UNICODE_CHAR_PORT);
final http:Client unicodeCharClient = check new (string `http://localhost:${UNICODE_CHAR_PORT}`);

service /greetings on unicodeCharListener {

    resource function get ආයුබෝවන්() returns string {
        return "සාදරයෙන් පිළිගනිමු";
    }

    resource function get வணக்கம்() returns string {
        return "வரவேற்கிறேன்";
    }

    resource function get こんにちは() returns string {
        return "ようこそ";
    }
};

@test:Config
function testUnicodeCharacters() returns error? {
    string path = check url:encode("ආයුබෝවන්", "UTF-8");
    string response = check unicodeCharClient->get("/greetings/" + path);
    test:assertEquals(response, "සාදරයෙන් පිළිගනිමු");

    response = check unicodeCharClient->/greetings/[path];
    test:assertEquals(response, "සාදරයෙන් පිළිගනිමු");

    path = check url:encode("வணக்கம்", "UTF-8");
    response = check unicodeCharClient->get("/greetings/" + path);
    test:assertEquals(response, "வரவேற்கிறேன்");

    response = check unicodeCharClient->/greetings/[path];
    test:assertEquals(response, "வரவேற்கிறேன்");

    path = check url:encode("こんにちは", "UTF-8");
    response = check unicodeCharClient->get("/greetings/" + path);
    test:assertEquals(response, "ようこそ");

    response = check unicodeCharClient->/greetings/[path];
    test:assertEquals(response, "ようこそ");
}
