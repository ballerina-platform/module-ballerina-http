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

import ballerina/log;
import ballerina/lang.'decimal;
import ballerina/time;

// Based on https://tools.ietf.org/html/rfc7234#section-4.2.3
isolated function calculateCurrentResponseAge(Response cachedResponse) returns @tainted int {
    time:Seconds ageValue = getResponseAge(cachedResponse);
    time:Utc dateValue = getDateValue(cachedResponse);
    time:Utc now = time:utcNow();
    time:Utc responseTime = cachedResponse.receivedTime;
    time:Utc requestTime = cachedResponse.requestTime;

    time:Seconds ageDiff = time:utcDiffSeconds(responseTime, dateValue);
    time:Seconds apparentAge = ageDiff >= 0d ? ageDiff : 0d;

    time:Seconds responseDelay = time:utcDiffSeconds(responseTime, requestTime);
    time:Seconds correctedAgeValue = ageValue + responseDelay;

    time:Seconds correctedInitialAge = apparentAge > correctedAgeValue ? apparentAge : correctedAgeValue;
    time:Seconds residentTime = time:utcDiffSeconds(now, responseTime);

    return <int>((correctedInitialAge + residentTime));
}

isolated function getResponseAge(Response cachedResponse) returns @tainted time:Seconds {
    string|error ageHeaderString = cachedResponse.getHeader(AGE);
    if (ageHeaderString is error) {
        return 0;
    } else {
        var ageValue = 'decimal:fromString(ageHeaderString);
        return (ageValue is decimal) ? <time:Seconds> ageValue : 0;
    }
}

isolated function getDateValue(Response inboundResponse) returns time:Utc {
    string|error dateHeader = inboundResponse.getHeader(DATE);
    if (dateHeader is string) {
        // TODO: May need to handle invalid date headers
        var dateHeaderTime = utcFromString(dateHeader, RFC_1123_DATE_TIME);
        return (dateHeaderTime is time:Utc) ? dateHeaderTime : [0, 0.0];
    }

    log:printDebug("Date header not found. Using current time for the Date header.");

    // Based on https://tools.ietf.org/html/rfc7231#section-7.1.1.2
    time:Utc currentT = time:utcNow();
    string timeStr = <string> checkpanic utcToString(currentT, RFC_1123_DATE_TIME);

    inboundResponse.setHeader(DATE, timeStr);
    return currentT;
}
