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

// NOTE: All the tokens/credentials used in this test are dummy tokens/credentials and used only for testing purposes.

import ballerina/http;
import ballerina/regex;
import ballerina/test;
import ballerina/http_test_common as common;

const string KEYSTORE_PATH = common:KEYSTORE_PATH;
const string TRUSTSTORE_PATH = common:TRUSTSTORE_PATH;

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "sub": "admin",
//  "iss": "wso2",
//  "exp": 1925955724,
//  "jti": "100078234ba23",
//  "aud": [
//    "ballerina"
//  ],
//  "scp": "write"
//}
const string JWT1 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                    "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTcyNCwgIm" +
                    "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoid3JpdGUifQ.H99ufLvCLFA5i1gfCt" +
                    "klVdPrBvEl96aobNvtpEaCsO4v6_EgEZYz8Pg0B1Y7yJPbgpuAzXEg_CzowtfCTu3jUFf5FH_6M1fWGko5vpljtCb5Xknt_" +
                    "YPqvbk5fJbifKeXqbkCGfM9c0GS0uQO5ss8StquQcofxNgvImRV5eEGcDdybkKBNkbA-sJFHd1jEhb8rMdT0M0SZFLnhrPL" +
                    "8edbFZ-oa-ffLLls0vlEjUA7JiOSpnMbxRmT-ac6QjPxTQgNcndvIZVP2BHueQ1upyNorFKSMv8HZpATYHZjgnJQSpmt3Oa" +
                    "oFJ6pgzbFuniVNuqYghikCQIizqzQNfC7JUD8wA";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "iss": "wso2",
//  "sub": "admin",
//  "aud": [
//    "ballerina"
//  ],
//  "exp": 1945063251,
//  "nbf": 1629703251,
//  "iat": 1629703251,
//  "jti": "100078234ba23",
//  "scp": "read write update"
//}
const string JWT1_1 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV" +
                    "0k0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJpc3MiOiJ3c28yIiwgInN1YiI6ImFkbWluIiwgImF1ZCI6WyJiYWxsZXJpbm" +
                    "EiXSwgImV4cCI6MTk0NTA2MzI1MSwgIm5iZiI6MTYyOTcwMzI1MSwgImlhdCI6MTYyOTcwMzI1MSwgImp0aSI6IjEwMDA" +
                    "3ODIzNGJhMjMiLCAic2NwIjoicmVhZCB3cml0ZSB1cGRhdGUifQ.OVM6SsDKmD18neeQgCu5t3q91_wNqo9moJcP55hG7" +
                    "WpRfpNLuuhjwuzxWvphoKHUzegfRTXM5r56has9so6wIfMk2xG01QAt0XZSdS6WuhoB5PiKp5TIZ0y-i1zQ-sdPjaW7-r" +
                    "PP60AlkUNPYHaGgL56tgmqSSoQ9DmGYq3hA38IVGO80hdPEVCjcuE9gXBxaIcdz2IHokYxKrXCYUFAmjhRrfJia2Iv0eJ" +
                    "AzwZFvivGBbgdTQQeNzSlXFCbh-zvYAWaGtN1byzRoseVNA4peGL3hjfCC4L8X21gXfly5zXGojFkpRzK3dZw0kb0hfmX" +
                    "RZqU95xJkubBma567RqRHg";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "iss": "wso2",
//  "sub": "admin",
//  "aud": [
//    "ballerina"
//  ],
//  "exp": 1945063475,
//  "nbf": 1629703475,
//  "iat": 1629703475,
//  "jti": "100078234ba23",
//  "scp": [
//    "read",
//    "write",
//    "update"
//  ]
//}
const string JWT1_2 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV" +
                    "0k0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJpc3MiOiJ3c28yIiwgInN1YiI6ImFkbWluIiwgImF1ZCI6WyJiYWxsZXJpbm" +
                    "EiXSwgImV4cCI6MTk0NTA2MzQ3NSwgIm5iZiI6MTYyOTcwMzQ3NSwgImlhdCI6MTYyOTcwMzQ3NSwgImp0aSI6IjEwMDA" +
                    "3ODIzNGJhMjMiLCAic2NwIjpbInJlYWQiLCAid3JpdGUiLCAidXBkYXRlIl19.fSSB4RLBWoqui00EfSywO8DdmDzddyG" +
                    "0hgjjLdbH9cTjCbOvhBsIPZqM4anrxavSKLvtDJFU9qJfKZd_ZKG6McKB681GB2P0xOaNtA1hHSotKbR0byUkXWIB2HEe" +
                    "Dw17uyLYC5XqJH0WUGQiSN6Tvi5ed6Pme2xcVfwdh_8La7zY110d2_doncgYL2MqjVKV2mmithNgFiHeWMrUpuchKH7rX" +
                    "8UO-yF3038ByI52ii3CcUgYPv26Pp4f1HfPKS9CBcpIjJUicoVWsyDrXB8MqCi4ik2w9hVDQPX7_rI_U9-BnmVSHC9Uui" +
                    "qEnVreHdsYlkn33dkM_clQcQ6O1Ftp8A";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "sub": "admin",
//  "iss": "wso2",
//  "exp": 1925955876,
//  "jti": "100078234ba23",
//  "aud": [
//    "ballerina"
//  ],
//  "scp": "read"
//}
const string JWT2 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV0k" +
                    "0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJzdWIiOiJhZG1pbiIsICJpc3MiOiJ3c28yIiwgImV4cCI6MTkyNTk1NTg3NiwgIm" +
                    "p0aSI6IjEwMDA3ODIzNGJhMjMiLCAiYXVkIjpbImJhbGxlcmluYSJdLCAic2NwIjoicmVhZCJ9.MVx_bJJpRyQryrTZ1-WC" +
                    "1BkJdeBulX2CnxYN5Y4r1XbVd0-rgbCQ86jEbWvLZOybQ8Hx7MB9thKaBvidBnctgMM1JzG-ULahl-afoyTCv_qxMCS-5B7" +
                    "AUA1f-sOQHzq-n7T3b0FKsWtmOEXbGmRxQFv89_v8xwUzIItXtZ6IjkoiZn5GerGrozX0DEBDAeG-2BOj8gSlsFENdPB5Sn" +
                    "5oEM6-Chrn6KFLXo3GFTwLQELgYkIGjgnMQfbyLLaw5oyJUyOCCsdMZ4oeVLO2rdKZs1L8ZDnolUfcdm5mTxxP9A4mTOTd-" +
                    "xC404MKwxkRhkgI4EJkcEwMHce2iCInZer10Q";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "iss": "wso2",
//  "sub": "admin",
//  "aud": [
//    "ballerina"
//  ],
//  "exp": 1945071465,
//  "nbf": 1629711465,
//  "iat": 1629711465,
//  "jti": "100078234ba23",
//  "scp": "read delete"
//}
const string JWT2_1 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV" +
                    "0k0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJpc3MiOiJ3c28yIiwgInN1YiI6ImFkbWluIiwgImF1ZCI6WyJiYWxsZXJpbm" +
                    "EiXSwgImV4cCI6MTk0NTA3MTQ2NSwgIm5iZiI6MTYyOTcxMTQ2NSwgImlhdCI6MTYyOTcxMTQ2NSwgImp0aSI6IjEwMDA" +
                    "3ODIzNGJhMjMiLCAic2NwIjoicmVhZCBkZWxldGUifQ.bSdUIzHgRzbAtuP_3uvDrX7hwdCK58b8k_tvfaW5vl1k06QM6" +
                    "tP97P_7h7zoyovBFzGwcgvkW_UhyiTtgF61I28xqidnn9b2reUlq9Rt8LCgs5D0nUp8x-axJ9ug6HcF10vKZ7O0BLbUmX" +
                    "QeBUvjv3MehjFVQJcZ6PhGTGVrw6m6xh8ghx2j-qu8v9I6dyZ0rKplR-5xsw04daGTyi3walOu5uXv3NVp74SfR1rkb1E" +
                    "_A-sQZOqoFpy3Ta9mo9rjFJ8bPQT1fioFHKxESuGit6zeZiwk3fugFuSjeqIAGzWr_gJdjGts08flYWgy7zIXbJTqn5Cv" +
                    "4AwXNt0AfdddYg";

//{
//  "alg": "RS256",
//  "typ": "JWT",
//  "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ"
//}
//{
//  "iss": "wso2",
//  "sub": "admin",
//  "aud": [
//    "ballerina"
//  ],
//  "exp": 1945071431,
//  "nbf": 1629711431,
//  "iat": 1629711431,
//  "jti": "100078234ba23",
//  "scp": [
//    "read",
//    "delete"
//  ]
//}
const string JWT2_2 = "eyJhbGciOiJSUzI1NiIsICJ0eXAiOiJKV1QiLCAia2lkIjoiTlRBeFptTXhORE15WkRnM01UVTFaR00wTXpFek9ESmhaV" +
                    "0k0TkRObFpEVTFPR0ZrTmpGaU1RIn0.eyJpc3MiOiJ3c28yIiwgInN1YiI6ImFkbWluIiwgImF1ZCI6WyJiYWxsZXJpbm" +
                    "EiXSwgImV4cCI6MTk0NTA3MTQzMSwgIm5iZiI6MTYyOTcxMTQzMSwgImlhdCI6MTYyOTcxMTQzMSwgImp0aSI6IjEwMDA" +
                    "3ODIzNGJhMjMiLCAic2NwIjpbInJlYWQiLCAiZGVsZXRlIl19.R8ddL_Iv1cBq2KtTEWdeIY_WiVkvsxFY9V8Ld08ZpHn" +
                    "CiC9BktQ9KQfX7DO81fv49J8A5vRybCeheDk4bd7_0YJsk-qQHkf_VQ6dLahwLJE8eJEOug91OLK8EsqsHcj36Mnnr7mT" +
                    "u0jAbIhOoPsoofbMr8HJ2NtIXtEGLZI8UgWdP8Do9IU-tRQ1JJMtjl5a1Mb42UaHNSIK09bs87lbf8_C_r2V0NoIyojSO" +
                    "58IwYNhrVegJDHIH2UCJz9MyE01_L_p7LOiCJQL88p0s-P7aYX3VgKm5rd2romP-R4E6dYiiTLHoaLFSxL5OhHwgRNVo3" +
                    "jm3iyc18Pq_mtNmLnaVQ";
//{
//  "alg": "HS256",
//  "typ": "JWT"
//}
//{
//  "sub": "1234567890",
//  "name": "John Doe",
//  "iat": 1516239022
//}
const string JWT3 = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0Ij" +
                    "oxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";

const string ACCESS_TOKEN_1 = "2YotnFZFEjr1zCsicMWpAA";
const string ACCESS_TOKEN_2 = "1zCsicMWpAA2YotnFZFEjr";
const string ACCESS_TOKEN_3 = "invalid-token";

http:ListenerConfiguration http2SslServiceConf = {
    secureSocket: {
        key: {
            path: common:KEYSTORE_PATH,
            password: "ballerina"
        }
    }
};

listener http:Listener generalHTTP2Listener = new http:Listener(http2GeneralPort);
listener http:Listener generalHTTPS2Listener = new http:Listener(http2SslGeneralPort, http2SslServiceConf);


isolated function createDummyRequest() returns http:Request {
    http:Request request = new;
    request.rawPath = "/foo/bar";
    request.method = "GET";
    request.httpVersion = http:HTTP_1_1;
    return request;
}

isolated function createSecureRequest(string headerValue) returns http:Request {
    http:Request request = createDummyRequest();
    request.addHeader(http:AUTH_HEADER, headerValue);
    return request;
}

isolated function sendNoTokenRequest(string path) returns http:Response|http:ClientError {
    http:Client clientEP = check new ("https://localhost:" + securedListenerPort.toString(),
        secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
    );
    return clientEP->get(path);
}

isolated function sendBasicTokenRequest(string path, string username, string password) returns http:Response|http:ClientError {
    http:Client clientEP = check new ("https://localhost:" + securedListenerPort.toString(),
        auth = {
        username: username,
        password: password
    },
        secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
    );
    return clientEP->get(path);
}

isolated function sendBearerTokenRequest(string path, string token) returns http:Response|http:ClientError {
    http:Client clientEP = check new ("https://localhost:" + securedListenerPort.toString(),
        auth = {
        token: token
    },
        secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
    );
    return clientEP->get(path);
}

isolated function sendJwtRequest(string path) returns http:Response|http:ClientError {
    http:Client clientEP = check new ("https://localhost:" + securedListenerPort.toString(),
        auth = {
        username: "admin",
        issuer: "wso2",
        audience: ["ballerina"],
        jwtId: "100078234ba23",
        keyId: "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ",
        customClaims: {"scp": "write"},
        signatureConfig: {
            config: {
                keyStore: {
                    path: KEYSTORE_PATH,
                    password: "ballerina"
                },
                keyAlias: "ballerina",
                keyPassword: "ballerina"
            }
        }
    },
        secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
    );
    return clientEP->get(path);
}

isolated function sendOAuth2TokenRequest(string path) returns http:Response|http:ClientError {
    http:Client clientEP = check new ("https://localhost:" + securedListenerPort.toString(),
        auth = {
        tokenUrl: "https://localhost:" + stsPort.toString() + "/oauth2/token",
        clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxStwNEW4cfStBEGRxRL68",
        clientSecret: "9205371918321623741",
        clientConfig: {
            secureSocket: {
                cert: {
                    path: TRUSTSTORE_PATH,
                    password: "ballerina"
                }
            }
        }
    },
        secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
    );
    return clientEP->get(path);
}

isolated function assertSuccess(http:Response|http:ClientError response) {
    if response is http:Response {
        test:assertEquals(response.statusCode, 200);
    } else {
        test:assertFail("Test Failed!");
    }
}

isolated function assertForbidden(http:Response|http:ClientError response) {
    if response is http:Response {
        test:assertEquals(response.statusCode, 403);
    } else {
        test:assertFail("Test Failed!");
    }
}

isolated function assertUnauthorized(http:Response|http:ClientError response) {
    if response is http:Response {
        test:assertEquals(response.statusCode, 401);
    } else {
        test:assertFail("Test Failed!");
    }
}

public type AuthResponse record {|
    *http:Ok;
    json body?;
|};

// The mock authorization server, based with https://hub.docker.com/repository/docker/ldclakmal/ballerina-sts
listener http:Listener sts = new (stsPort, {
    secureSocket: {
        key: {
            path: KEYSTORE_PATH,
            password: "ballerina"
        }
    }
});

service /oauth2 on sts {
    resource function post token() returns AuthResponse {
        return {
            body: {
                "access_token": ACCESS_TOKEN_1,
                "token_type": "example",
                "expires_in": 3600,
                "example_parameter": "example_value"
            }
        };
    }

    resource function post introspect(http:Request request) returns AuthResponse {
        string|http:ClientError payload = request.getTextPayload();
        if payload is string {
            string[] parts = regex:split(payload, "&");
            foreach string part in parts {
                if part.indexOf("token=") is int {
                    string token = regex:split(part, "=")[1];
                    if token == ACCESS_TOKEN_1 {
                        return {
                            body: {"active": true, "exp": 3600, "scp": "write update"}
                        };
                    } else if token == ACCESS_TOKEN_2 {
                        return {
                            body: {"active": true, "exp": 3600, "scp": "read"}
                        };
                    } else {
                        return {
                            body: {"active": false}
                        };
                    }
                }
            }
        }
        return {};
    }
}
