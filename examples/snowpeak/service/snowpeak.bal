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
import 'service.representations as rep;
import 'service.mock;

configurable int port = 9090;

# A fake mountain resort
@http:ServiceConfig { mediaTypeSubtypePrefix: "vnd.snowpeak.resort", cors: { allowOrigins: ["*"] }}
service /snowpeak on new http:Listener(port) {

    # Snowpeak locations resource
    # 
    # + return - `Location` or `SnowpeakError` representation
    @http:ResourceConfig {
        name: "Locations",
        linkedTo: [{ name: "Rooms", relation: "room" }]
    }
    resource function get locations() returns @http:Payload{mediaType: "application/json"}
                @http:Cache rep:Locations|rep:SnowpeakInternalError {
        do {
            return check mock:getLocations();
        } on fail var e {
            return { body: { msg: e.toString() }};
        }
    }

    # Snowpeak rooms resource 
    # 
    # + id - Unique identification of location
    # + startDate - Start date in format yyyy-mm-dd
    # + endDate - End date in format yyyy-mm-dd
    # + return - `Rooms` or `SnowpeakError` representation
    @http:ResourceConfig {
        name: "Rooms",
        linkedTo: [{ name: "Reservations", relation: "reservation" }]
    }
    resource function get locations/[string id]/rooms(string startDate, string endDate)
                returns rep:Rooms|rep:SnowpeakInternalError {
        do {
            return check mock:getRooms(startDate, endDate);
        } on fail var e {
            return { body: { msg: e.toString() }};
        }
    }

    # Snowpeak create reservation resource
    #
    # + reservation - Reservation representation
    # + return - `ReservationCreated` or `SnowpeakError` representation
    @http:ResourceConfig {
        name: "Reservations",
        linkedTo: [
            { name: "Reservation", relation: "edit", method: "put" },
            { name: "Reservation", relation: "cancel", method: "delete" },
            { name: "Payment", relation: "payment" }
        ]
    }
    resource function post reservations(@http:Payload rep:Reservation reservation)
                returns rep:ReservationReceipt|rep:ReservationConflict|rep:SnowpeakInternalError {
        do {
            return check mock:createReservation(reservation);
        } on fail var e {
            return <rep:SnowpeakInternalError>{ body: { msg: e.toString() }};
        }
    }

    # Snowpeak create/update reservation resource
    #
    # + reservation - Reservation representation
    # + return - `ReservationUpdated`, `ReservationConflict` or `SnowpeakError` representation
    @http:ResourceConfig {
        name: "Reservation",
        linkedTo: [
            { name: "Reservation", relation: "cancel", method: "delete" },
            { name: "Payment", relation: "payment" }
        ]
    }
    resource function put reservations/[string id](@http:Payload rep:Reservation reservation)
                returns rep:ReservationUpdated|rep:ReservationConflict|rep:SnowpeakInternalError {
        do {
            return check mock:updateReservation(id, reservation);
        } on fail var e {
            return <rep:SnowpeakInternalError>{ body: { msg: e.toString() }};
        }
    }

    # Snowpeak cancel reservation resource
    # 
    # + id - Unique identification of reservation
    # + return - `ReservationCanceled` or `SnowpeakError` representation
    @http:ResourceConfig {
        name: "Reservation"
    }
    resource function delete reservations/[string id]() returns
                            rep:ReservationCanceled|rep:SnowpeakInternalError {
        do {
            return check mock:cancelReservation(id);
        } on fail var e {
            return <rep:SnowpeakInternalError>{ body: { msg: e.toString() }};
        }
    }

    # Snowpeak payment resource 
    # 
    # + id - Unique identification of reservation
    # + payment - Payment representation
    # + return - `PaymentCreated`, `PaymentConflict` or `SnowpeakError` representation
    @http:ResourceConfig {
        name: "Payment"
    }
    resource function post payments/[string id](@http:Payload rep:Payment payment)
                returns rep:PaymentReceipt|rep:PaymentConflict|rep:SnowpeakInternalError {
        do {
            return check mock:createPayment(id, payment);
        } on fail var e {
            return <rep:SnowpeakInternalError>{ body: { msg: e.toString() }};
        }
    }
}
