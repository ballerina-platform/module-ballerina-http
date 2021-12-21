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
import 'client.representations as rep;

public function main() returns error? {
    
    final http:Client snowpeak = check new ("http://localhost:9090", {
        compression: http:COMPRESSION_ALWAYS
    });

    // start with the well-known url
    rep:Locations locations = check snowpeak->get("/snowpeak/locations");

    // get the available rooms
    string startDate = "2021-08-01";
    string endDate = "2021-08-01";
    string targetUrl = string `${locations.locations[0].links[0].href}?startDate=${startDate}&endDate=${endDate}`;
    rep:Rooms rooms = check snowpeak->get(targetUrl);

    // make the reservation
    rep:Reservation reservation = {
        "reserveRooms": [
            {
                "id": rooms.rooms[0].id,
                "count": 1
            }
        ],
        "startDate": "2021-08-01",
        "endDate": "2021-08-03"
    };
    rep:ReservationReceipt recervationReciept = check snowpeak->put(rooms.links[0].href, reservation);

    // do the payment
    rep:Payment payment = {
        "cardholderName": "Joe Biden",
        "cardNumber": 4444555566667777,
        "expiryMonth": 9,
        "expiryYear": 2033
    };
    rep:PaymentReceipt paymentReceipt = check snowpeak->put(recervationReciept.links[2].href, payment);
}
