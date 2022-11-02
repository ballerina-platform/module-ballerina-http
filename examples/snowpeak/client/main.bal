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
import ballerina/regex;
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
    string targetUrl = string `${regex:replace(string`${locations._links.get("room").href}`,
                                               "\\{id}", locations.locations[0].id)}?startDate=${startDate}&endDate=${endDate}`;
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
    rep:ReservationReceipt reservationReceipt = check snowpeak->post(rooms._links.get("reservation").href, reservation);

    // update the reservation
    reservation = {
        "reserveRooms": [
            {
                "id": rooms.rooms[0].id,
                "count": 3
            }
        ],
        "startDate": "2021-08-01",
        "endDate": "2021-08-03"
    };
    targetUrl = string `${regex:replace(string`${reservationReceipt._links.get("edit").href}`,
                                        "\\{id}", reservationReceipt.id)}`;
    rep:ReservationReceipt updatedReservationReceipt = check snowpeak->put(targetUrl, reservation);

    // do the payment
    rep:Payment payment = {
        "cardholderName": "Joe Biden",
        "cardNumber": 4444555566667777,
        "expiryMonth": 9,
        "expiryYear": 2033
    };
    targetUrl = string `${regex:replace(string`${updatedReservationReceipt._links.get("payment").href}`,
                                        "\\{id}", updatedReservationReceipt.id)}`;
    rep:PaymentReceipt paymentReceipt = check snowpeak->post(targetUrl, payment);
}
