// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/http;
import ballerina/test;

http:Link link1 = {
    href : "/source/test/testLink1",
    types : ["testMediaType1"],
    methods : [http:GET, http:POST]
};

http:Link link2 = {
    href : "/source/test/testLink2",
    types : ["testMediaType2"],
    methods : [http:OPTIONS, http:HEAD]
};

http:Links links = {
    _links : {
        "rel1" : link1,
        "rel2" : link2
    }
};

@test:Config{}
public function testLinkRecords() {
    test:assertEquals(links._links["rel1"]?.href, "/source/test/testLink1");
    test:assertEquals(links._links["rel1"]?.methods, [http:GET, http:POST]);
    test:assertEquals(links._links["rel1"]?.types, ["testMediaType1"]);

    test:assertEquals(links._links["rel2"]?.href, "/source/test/testLink2");
    test:assertEquals(links._links["rel2"]?.methods, [http:OPTIONS, http:HEAD]);
    test:assertEquals(links._links["rel2"]?.types, ["testMediaType2"]);
}
