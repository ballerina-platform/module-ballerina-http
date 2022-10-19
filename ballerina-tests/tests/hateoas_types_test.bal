// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/test;

public type ReturnType string|xml|map<string>;

service /hateoas on new http:Listener(hateoasTypesTestPort) {

    @http:ResourceConfig {
        linkedTo: [
            {name:"link1", relation: "link1"},
            {name:"link2", relation: "link2"},
            {name:"link3", relation: "link3"},
            {name:"link4", relation: "link4"},
            {name:"link5", relation: "link5"},
            {name:"link6", relation: "link6"},
            {name:"link7", relation: "link7"},
            {name:"link8", relation: "link8"},
            {name:"link9", relation: "link9"},
            {name:"link10", relation: "link10"}
        ]
    }
    resource function get links() returns http:Ok {
        return {body: {message: "Links returned"}};
    }

    @http:ResourceConfig {
        name: "link1"
    }
    resource function get link1() returns string {
        return "Hello, from resource link1";
    }

    @http:ResourceConfig {
        name: "link2"
    }
    resource function get link2() returns xml {
        return xml`<message>Hello, from resource link2</message>`;
    }

    @http:ResourceConfig {
        name: "link3"
    }
    resource function get link3() returns byte[] {
        return "Hello, from resource link3".toBytes();
    }

    @http:ResourceConfig {
        name: "link4"
    }
    resource function get link4() returns @http:Payload{mediaType: "application/json"} http:Response {
        http:Response res = new;
        res.setTextPayload("Hello, from resource link4");
        return res;
    }

    @http:ResourceConfig {
        name: "link5"
    }
    resource function get link5() returns http:Ok {
        return {body: "Hello, from resource lin5"};
    }

    @http:ResourceConfig {
        name: "link6"
    }
    resource function get lin6() returns string|xml {
        return "Hello, from resource link6";
    }

    @http:ResourceConfig {
        name: "link7"
    }
    resource function get link7() returns ReturnType {
        return "Hello, from resource link7";
    }

    @http:ResourceConfig {
        name: "link8"
    }
    resource function get link8() returns http:Response|error? {
        return;
    }

    @http:ResourceConfig {
        name: "link9"
    }
    resource function get link9() returns @http:Payload{mediaType: "application/json"} string|xml {
        return xml`<message>Hello, from resource link9</message>`;
    }

    @http:ResourceConfig {
        name: "link10"
    }
    resource function get link10() { }
}


final http:Client hateoasTypesTestClient = check new("http://localhost:" + hateoasTypesTestPort.toString());

type HateoasTypesResponse record {|
    *http:Links;
    string message;
|};

@test:Config {}
function testHateoasTypes() returns error? {
    HateoasTypesResponse response = check hateoasTypesTestClient->get("/hateoas/links");
    map<http:Link> expectedLinks = {
        "link1": {
            href: "/hateoas/link1",
            types: [ "text/plain" ],
            methods: [ http:GET ]
        },
        "link2": {
            href: "/hateoas/link2",
            types: [ "application/xml" ],
            methods: [ http:GET ]
        },
        "link3": {
            href: "/hateoas/link3",
            types: [ "application/octet-stream" ],
            methods: [ http:GET ]
        },
        "link4": {
            href: "/hateoas/link4",
            types: [ "application/json" ],
            methods: [ http:GET ]
        },
        "link5": {
            href: "/hateoas/link5",
            types: [ "application/json" ],
            methods: [ http:GET ]
        },
        "link6": {
            href: "/hateoas/lin6",
            types: [
                "application/xml",
                "text/plain"
            ],
            methods: [ http:GET ]
        },
        "link7": {
            href: "/hateoas/link7",
            types: [
                "application/xml",
                "application/json",
                "text/plain"
            ],
            methods: [ http:GET ]
        },
        "link8": {
            href: "/hateoas/link8",
            methods: [ http:GET ]
        },
        "link9": {
            href: "/hateoas/link9",
            types: [ "application/json" ],
            methods: [ http:GET ]
        },
        "link10": {
            href: "/hateoas/link10",
            methods: [ http:GET ]
        }
    };
    test:assertEquals(response._links, expectedLinks);
}
