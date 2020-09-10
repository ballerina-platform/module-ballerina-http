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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/stringutils;
import ballerina/test;

const string CONTENT_TYPE = "content-type";
const string CONTENT_ENCODING = "content-encoding";
const string ACCEPT_ENCODING = "accept-encoding";
const string CONTENT_LENGTH = "content-length";
const string LOCATION = "location";
const string ORIGIN = "origin";
const string ALLOW = "Allow";
const string ACCESS_CONTROL_ALLOW_ORIGIN = "access-control-allow-origin";
const string ACCESS_CONTROL_ALLOW_CREDENTIALS = "access-control-allow-credentials";
const string ACCESS_CONTROL_ALLOW_HEADERS = "access-control-allow-headers";
const string ACCESS_CONTROL_ALLOW_METHODS = "access-control-allow-methods";
const string ACCESS_CONTROL_EXPOSE_HEADERS = "access-control-expose-headers";
const string ACCESS_CONTROL_MAX_AGE = "access-control-max-age";
const string ACCESS_CONTROL_REQUEST_HEADERS = "access-control-request-headers";
const string ACCESS_CONTROL_REQUEST_METHOD = "access-control-request-method";

const string SERVER = "server";

const string ENCODING_GZIP = "gzip";
const string ENCODING_DEFLATE = "deflate";
const string HTTP_TRANSFER_ENCODING_IDENTITY = "identity";

const string HTTP_METHOD_GET = "GET";
const string HTTP_METHOD_POST = "POST";
const string HTTP_METHOD_PUT = "PUT";
const string HTTP_METHOD_PATCH = "PATCH";
const string HTTP_METHOD_DELETE = "DELETE";
const string HTTP_METHOD_OPTIONS = "OPTIONS";
const string HTTP_METHOD_HEAD = "HEAD";

const string TEXT_PLAIN = "text/plain";
const string APPLICATION_XML = "application/xml";
const string APPLICATION_JSON = "application/json";
const string APPLICATION_FORM = "application/x-www-form-urlencoded";

function assertJsonValue(json|error payload, string expectKey, json expectValue) {
    if payload is map<json> {
        test:assertEquals(payload[expectKey], expectValue, msg = "Found unexpected output");
    } else if payload is error {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertJsonPayload(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertTrueTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertTrue(stringutils:contains(payload, expectValue), msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

function assertHeaderValue(string headerKey, string expectValue) {
    test:assertEquals(headerKey, expectValue, msg = "Found unexpected headerValue");
}
