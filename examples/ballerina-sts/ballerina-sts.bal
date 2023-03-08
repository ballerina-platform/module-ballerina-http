import ballerina/http;
import ballerina/log;
import ballerina/regex;
import ballerina/uuid;

// Default values of mock authorization server.
configurable int HTTPS_SERVER_PORT = 9445;
configurable int HTTP_SERVER_PORT = 9444;
configurable int TOKEN_VALIDITY_PERIOD = 2; // in seconds

// Credentials of the mock authorization server.
configurable string USERNAME = "admin";
configurable string PASSWORD = "admin";
configurable string CLIENT_ID = "FlfJYKBD2c925h4lkycqNZlC2l4a";
configurable string CLIENT_SECRET = "PJz0UhTJMrHOo68QQNpvnqAY_3Aa";

// Values that the grant_type parameter can hold.
const GRANT_TYPE_CLIENT_CREDENTIALS = "client_credentials";
const GRANT_TYPE_PASSWORD = "password";
const GRANT_TYPE_REFRESH_TOKEN = "refresh_token";
const GRANT_TYPE_JWT_BEARER = "urn:ietf:params:oauth:grant-type:jwt-bearer";

string[] accessTokenStore = ["56ede317-4511-44b4-8579-a08f094ee8c5"];
string[] refreshTokenStore = ["24f19603-8565-4b5f-a036-88a945e1f272"];

// The mock authorization server, which is capable of issuing access tokens with related to the grant type and
// also of refreshing the already-issued access tokens. Also, capable of introspection the access tokens.
listener http:Listener sts1 = new (HTTPS_SERVER_PORT, {
    secureSocket: {
        key: {
            certFile: "./cert/public.crt",
            keyFile: "./cert/private.key"
        }
    }
});

listener http:Listener sts2 = new (HTTP_SERVER_PORT);

service /oauth2 on sts1, sts2 {

    function init() {
        log:printInfo("STS started on port: " + HTTPS_SERVER_PORT.toString() + " (HTTPS) & " + HTTP_SERVER_PORT.toString() + " (HTTP)");
    }

    // This issues an access token with reference to the received grant type (client credentials, password and refresh token grant type).
    resource function post token(http:Request req) returns json|http:Unauthorized|http:BadRequest|http:InternalServerError {
        var authorizationHeader = req.getHeader("Authorization");
        if authorizationHeader is string {
            if isAuthorizedTokenClient(authorizationHeader) {
                var payload = req.getTextPayload();
                if payload is string {
                    string[] params = regex:split(payload, "&");
                    string grantType = "";
                    string scopes = "";
                    string username = "";
                    string password = "";
                    string refreshToken = "";
                    foreach string param in params {
                        if param.includes("grant_type=") {
                            grantType = regex:split(param, "=")[1];
                        } else if param.includes("scope=") {
                            scopes = regex:split(param, "=")[1];
                        } else if param.includes("username=") {
                            username = regex:split(param, "=")[1];
                        } else if param.includes("password=") {
                            password = regex:split(param, "=")[1];
                        } else if param.includes("refresh_token=") {
                            refreshToken = regex:split(param, "=")[1];
                            // If the refresh token contains the `=` symbol, then it is required to concatenate all the
                            // parts of the value since the `split` function breaks all those into separate parts.
                            if param.endsWith("==") {
                                refreshToken += "==";
                            }
                        }
                    }
                    return prepareTokenResponse(grantType, username, password, refreshToken, scopes);
                }
                string description = "The request is malformed and failed to retrieve the text payload.";
                return createInvalidRequest(description);
            }
            string description = "Client authentication failed due to unknown client.";
            return createInvalidClient(description);
        } else {
            var payload = req.getTextPayload();
            if payload is string {
                if payload.includes("client_id") && payload.includes("client_secret") {
                    string[] params = regex:split(payload, "&");
                    string grantType = "";
                    string scopes = "";
                    string username = "";
                    string password = "";
                    string clientId = "";
                    string clientSecret = "";
                    string refreshToken = "";
                    foreach string param in params {
                        if param.includes("grant_type=") {
                            grantType = regex:split(param, "=")[1];
                        } else if param.includes("scope=") {
                            scopes = regex:split(param, "=")[1];
                        } else if param.includes("username=") {
                            username = regex:split(param, "=")[1];
                        } else if param.includes("password=") {
                            password = regex:split(param, "=")[1];
                        } else if param.includes("client_id=") {
                            clientId = regex:split(param, "=")[1];
                        } else if param.includes("client_secret=") {
                            clientSecret = regex:split(param, "=")[1];
                        } else if param.includes("refresh_token=") {
                            refreshToken = regex:split(param, "=")[1];
                            // If the refresh token contains the `=` symbol, then it is required to concatenate all the
                            // parts of the value since the `split` function breaks all those into separate parts.
                            if param.endsWith("==") {
                                refreshToken += "==";
                            }
                        }
                    }
                    if clientId == CLIENT_ID && clientSecret == CLIENT_SECRET {
                        return prepareTokenResponse(grantType, username, password, refreshToken, scopes);
                    }
                    string description = "Client authentication failed since no client authentication included.";
                    return createInvalidClient(description);
                }
                string description = "Client authentication failed due to unknown client.";
                return createInvalidClient(description);
            }
            string description = "The request is malformed and failed to retrieve the text payload.";
            return createInvalidRequest(description);
        }
    }

    resource function post introspect(http:Request req) returns json|http:Unauthorized|http:BadRequest {
        var authorizationHeader = req.getHeader("Authorization");
        if authorizationHeader is string {
            if isAuthorizedIntrospectionClient(authorizationHeader) {
                var payload = req.getTextPayload();
                if payload is string {
                    string[] params = regex:split(payload, "&");
                    string token = "";
                    string tokenTypeHint = "";
                    foreach string param in params {
                        if param.includes("token=") {
                            token = regex:split(param, "=")[1];
                            // If the access token contains the `=` symbol, then it is required to concatenate all the
                            // parts of the value since the `split` function breaks all those into separate parts.
                            if param.endsWith("==") {
                                token += "==";
                            }
                        } else if param.includes("token_type_hint=") {
                            tokenTypeHint = regex:split(param, "=")[1];
                        }
                    }
                    return prepareIntrospectionResponse(token, tokenTypeHint);
                }
                string description = "The request is malformed and failed to retrieve the text payload.";
                return createInvalidRequest(description);
            }
            string description = "Client authentication failed due to unknown client.";
            return createInvalidClient(description);
        }
        string description = "Client authentication failed since no client authentication included.";
        return createInvalidClient(description);
    }

    // This JWKs endpoint respond with a JSON object that represents a set of JWKs.
    // https://tools.ietf.org/html/rfc7517#section-5
    resource function get jwks() returns json {
        json jwks = {
            "keys": [{
                "kty": "EC",
                "crv": "P-256",
                "x": "MKBCTNIcKUSDii11ySs3526iDZ8AiTo7Tu6KPAqv7D4",
                "y": "4Etl6SRW2YiLUrN5vfvVHuhp7x8PxltmWWlbbM4IFyM",
                "use": "enc",
                "kid": "1"
            },
            {
                "kty": "RSA",
                "n": "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qMQvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPksINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw",
                "e": "AQAB",
                "alg": "RS256",
                "kid": "2011-04-29"
            },
            {
                "kty": "RSA",
                "e": "AQAB",
                "use": "sig",
                "kid": "NTAxZmMxNDMyZDg3MTU1ZGM0MzEzODJhZWI4NDNlZDU1OGFkNjFiMQ",
                "alg": "RS256",
                "n": "AIFcoun1YlS4mShJ8OfcczYtZXGIes_XWZ7oPhfYCqhSIJnXD3vqrUu4GXNY2E41jAm8dd7BS5GajR3g1GnaZrSqN0w3bjpdbKjOnM98l2-i9-JP5XoedJsyDzZmml8Xd7zkKCuDqZIDtZ99poevrZKd7Gx5n2Kg0K5FStbZmDbTyX30gi0_griIZyVCXKOzdLp2sfskmTeu_wF_vrCaagIQCGSc60Yurnjd0RQiMWA10jL8axJjnZ-IDgtKNQK_buQafTedrKqhmzdceozSot231I9dth7uXvmPSjpn23IYUIpdj_NXCIt9FSoMg5-Q3lhLg6GK3nZOPuqgGa8TMPs="
            }]
        };
        return jwks;
    }
}

function prepareTokenResponse(string grantType, string username, string password, string refreshToken, string scopes) returns json|http:Unauthorized|http:BadRequest|http:InternalServerError {
    if grantType == GRANT_TYPE_CLIENT_CREDENTIALS {
        string newAccessToken = uuid:createType4AsString();
        addToAccessTokenStore(newAccessToken);
        json response = {
            "access_token": newAccessToken,
            "token_type": "example",
            "expires_in": TOKEN_VALIDITY_PERIOD,
            "example_parameter": "example_value"
        };
        if scopes != "" {
            json|error mergedJson = response.mergeJson({"scope": scopes});
            if mergedJson is error {
                return <http:InternalServerError> {};
            }
            return <json> mergedJson;
        }
        return response;
    } else if grantType == GRANT_TYPE_PASSWORD {
        if username == USERNAME && password == PASSWORD {
            string newAccessToken = uuid:createType4AsString();
            addToAccessTokenStore(newAccessToken);
            string newRefreshToken = uuid:createType4AsString();
            addToRefreshTokenStore(newRefreshToken);
            json response = {
                "access_token": newAccessToken,
                "refresh_token": newRefreshToken,
                "token_type": "example",
                "expires_in": TOKEN_VALIDITY_PERIOD,
                "example_parameter": "example_value"
            };
            if scopes != "" {
                json|error mergedJson = response.mergeJson({"scope": scopes});
                if mergedJson is error {
                    return <http:InternalServerError> {};
                }
                return <json> mergedJson;
            }
            return response;
        }
        string description = "The authenticated client is not authorized to use password grant type.";
        return createUnauthorizedClient(description);
    } else if grantType == GRANT_TYPE_REFRESH_TOKEN {
        foreach string token in refreshTokenStore {
            if token == refreshToken {
                string newAccessToken = uuid:createType4AsString();
                addToAccessTokenStore(newAccessToken);
                string newRefreshToken = uuid:createType4AsString();
                addToRefreshTokenStore(newRefreshToken);
                json response = {
                    "access_token": newAccessToken,
                    "refresh_token": newRefreshToken,
                    "token_type": "example",
                    "expires_in": TOKEN_VALIDITY_PERIOD,
                    "example_parameter": "example_value"
                };
                if scopes != "" {
                    json|error mergedJson = response.mergeJson({"scope": scopes});
                    if mergedJson is error {
                        return <http:InternalServerError> {};
                    }
                    return <json> mergedJson;
                }
                return response;
            }
        }
        string description = "The provided refresh token is invalid, expired or revoked.";
        return createInvalidGrant(description);
    } else if grantType == GRANT_TYPE_JWT_BEARER {
        string newAccessToken = uuid:createType4AsString();
        addToAccessTokenStore(newAccessToken);
        json response = {
            "access_token": newAccessToken,
            "token_type": "example",
            "expires_in": TOKEN_VALIDITY_PERIOD,
            "example_parameter": "example_value"
        };
        if scopes != "" {
            json|error mergedJson = response.mergeJson({"scope": scopes});
            if mergedJson is error {
                return <http:InternalServerError> {};
            }
            return <json> mergedJson;
        }
        return response;
    }
    string description = "The authorization grant type is not supported by the authorization server.";
    return createUnsupportedGrant(description);
}

function prepareIntrospectionResponse(string accessToken, string tokenTypeHint) returns json {
    foreach string token in accessTokenStore {
        if token == accessToken {
            json response = {
                "active": true,
                "scope": "read write dolphin",
                "client_id": "l238j323ds-23ij4",
                "username": "jdoe",
                "token_type": "token_type",
                "exp": TOKEN_VALIDITY_PERIOD,
                "iat": 1419350238,
                "nbf": 1419350238,
                "sub": "Z5O3upPC88QrAjx00dis",
                "aud": "https://protected.example.net/resource",
                "iss": "https://server.example.com/",
                "jti": "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
                "extension_field": "twenty-seven",
                "scp": "admin"
            };
            return response;
        }
    }
    json response = {"active": false};
    return response;
}

function isAuthorizedTokenClient(string authorizationHeader) returns boolean {
    string clientIdSecret = CLIENT_ID + ":" + CLIENT_SECRET;
    string expectedAuthorizationHeader = "Basic " + clientIdSecret.toBytes().toBase64();
    return authorizationHeader == expectedAuthorizationHeader;
}

function isAuthorizedIntrospectionClient(string authorizationHeader) returns boolean {
    string usernamePassword = USERNAME + ":" + PASSWORD;
    string expectedAuthorizationHeader = "Basic " + usernamePassword.toBytes().toBase64();
    return authorizationHeader == expectedAuthorizationHeader;
}

function addToAccessTokenStore(string accessToken) {
    int index = accessTokenStore.length();
    accessTokenStore[index] = accessToken;
}

function addToRefreshTokenStore(string refreshToken) {
    int index = refreshTokenStore.length();
    refreshTokenStore[index] = refreshToken;
}

// Error responses. (Refer: https://tools.ietf.org/html/rfc6749#section-5.2)
function createInvalidClient(string description) returns http:Unauthorized {
    return {
        body: {
            "error": "invalid_client",
            "error_description": description
        }
    };
}

function createUnauthorizedClient(string description) returns http:Unauthorized {
    return {
        body: {
            "error": "unauthorized_client",
            "error_description": description
        }
    };
}

function createInvalidRequest(string description) returns http:BadRequest {
    return {
        body: {
            "error": "invalid_request",
            "error_description": description
        }
    };
}

function createInvalidGrant(string description) returns http:BadRequest {
    return {
        body: {
            "error": "invalid_grant",
            "error_description": description
        }
    };
}

function createUnsupportedGrant(string description) returns http:BadRequest {
    return {
        body: {
            "error": "unsupported_grant_type",
            "error_description": description
        }
    };
}
