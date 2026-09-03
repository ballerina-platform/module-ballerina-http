// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com)
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

listener http:Listener plainListener = new (9090);

listener http:Listener securedListener = new (9091, secureSocket = {
    key: {
        certFile: "/path/to/public.crt",
        keyFile: "/path/to/private.key"
    }
});

// Credentials cross the network in the clear on a listener declared elsewhere
@http:ServiceConfig {
    auth: [
        {
            signatureConfig: {
                certFile: "/path/to/public.crt"
            },
            issuer: "wso2",
            audience: "ballerina",
            scopes: ["admin"]
        }
    ]
}
service /namedListener on plainListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// The same on a listener constructed inline
@http:ServiceConfig {
    auth: [
        {
            signatureConfig: {
                certFile: "/path/to/public.crt"
            },
            issuer: "wso2",
            audience: "ballerina",
            scopes: ["admin"]
        }
    ]
}
service /inlineListener on new http:Listener(9092) {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - credentials carried over TLS
@http:ServiceConfig {
    auth: [
        {
            signatureConfig: {
                certFile: "/path/to/public.crt"
            },
            issuer: "wso2",
            audience: "ballerina",
            scopes: ["admin"]
        }
    ]
}
service /secured on securedListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - a plaintext listener carrying no credentials
service /public on plainListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - no authentication provider is configured at all
@http:ServiceConfig {
    auth: []
}
service /noProvider on plainListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - a ServiceConfig from another module, whose auth is unrelated to HTTP authentication
@custom:ServiceConfig {
    auth: ["admin"]
}
service /otherAnnotation on plainListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - the listener configuration is held in a variable that carries TLS
final http:ListenerConfiguration & readonly declaredConfig = {
    secureSocket: {
        key: {
            certFile: "/path/to/public.crt",
            keyFile: "/path/to/private.key"
        }
    }
};

listener http:Listener declaredConfigListener = new (9093, declaredConfig);

@http:ServiceConfig {
    auth: [
        {
            signatureConfig: {
                certFile: "/path/to/public.crt"
            },
            issuer: "wso2",
            audience: "ballerina",
            scopes: ["admin"]
        }
    ]
}
service /declaredConfig on declaredConfigListener {
    resource function get greet() returns string {
        return "Hello";
    }
}

// Negative case - a listener configuration this analysis cannot read is not guessed at
function getListenerConfig() returns http:ListenerConfiguration => {};

listener http:Listener opaqueConfigListener = new (9094, getListenerConfig());

@http:ServiceConfig {
    auth: [
        {
            signatureConfig: {
                certFile: "/path/to/public.crt"
            },
            issuer: "wso2",
            audience: "ballerina",
            scopes: ["admin"]
        }
    ]
}
service /opaqueConfig on opaqueConfigListener {
    resource function get greet() returns string {
        return "Hello";
    }
}
