// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

final http:Client callCountryTestClient = check new("http://localhost:" + http2GeneralPort.toString());

public type Country record {
    string name;
};

service on generalHTTP2Listener {

    resource function get country/[int callingCode]() returns string|error {
        http:Client restCountriesEp = check new ("https://restcountries.com");
        Country[] countries = check restCountriesEp->get("/v2/callingcode/" + callingCode.toString());
        if countries.length() == 0 {
            return "Invalid Calling Code";
        }
        return countries[0].name;
    }

    resource function get countryLocal/[int callingCode]() returns string|error {
        http:Client restCountriesEp = check new ("https://localhost:" + http2SslGeneralPort.toString(), http2SslClientConf1);
        string country = check restCountriesEp->get("/restcountries/v2/callingcode/" + callingCode.toString());
        return country;
    }
}

service /restcountries/v2 on generalHTTPS2Listener {

    resource function get callingcode/[int callingCode]() returns string {
        return "American Samoa";
    }
}

@test:Config {enable: false}
function testWellknownCertBackendWithinService() returns error? {
    string response = check callCountryTestClient->get("/country/1");
    test:assertEquals(response, "American Samoa", msg = "Found unexpected output");

    response = check callCountryTestClient->get("/country/1");
    test:assertEquals(response, "American Samoa", msg = "Found unexpected output");
}

@test:Config {enable: false}
function testWellknownCertBackendWithinServiceDifferentClient() returns error? {
    string response = check callCountryTestClient->get("/country/1");
    test:assertEquals(response, "American Samoa", msg = "Found unexpected output");

    http:Client callCountryTestClientDiff = check new("http://localhost:" + http2GeneralPort.toString());
    response = check callCountryTestClientDiff->get("/country/1");
    test:assertEquals(response, "American Samoa", msg = "Found unexpected output");
}

@test:Config {enable: false}
function testWellknownCertBackendWithinLocalService() returns error? {
    string response = check callCountryTestClient->get("/countryLocal/1");
    test:assertEquals(response, "American Samoa", msg = "Found unexpected output");

    response = check callCountryTestClient->get("/countryLocal/1");
    test:assertEquals(response, "American Samoa", msg = "Found unexpected output");
}

@test:Config {dependsOn:[testWellknownCertBackendWithinService], enable: false}
function testWellknownCertBackendWithinFunction() returns error? {
    http:Client restCountriesEp = check new ("https://restcountries.com");
    Country[] countries = check restCountriesEp->get("/v2/callingcode/1");
    test:assertEquals(countries[0].name, "American Samoa", msg = "Found unexpected output");
}
