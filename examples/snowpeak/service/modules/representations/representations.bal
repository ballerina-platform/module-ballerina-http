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

# Represents location
public type Location record {|
    *http:Links;
    # Name of the location
    string name;
    # Unique identification of the location
    string id;
    # Address of the location
    string address;
|};
# Represents a collection of locations
public type Locations record {|
    # collection of locations
    Location[] locations;
|};

public enum RoomCategory {
    DELUXE,
    KING,
    FAMILY
}
public enum RoomStatus {
    AVAILABLE,
    RESERVED,
    BOOKED
}
public enum ReservationState {
    VALID,
    CANCELED
}

# Represents resort room
public type Room record {|
    # Unique identification of the room
    string id;
    #Types of rooms available
    RoomCategory category;
    # Number of people that can be accommodate
    int capacity;
    # Availability of wifi
    boolean wifi;
    # Availability of room
    RoomStatus status;
    # Currency used in price
    string currency;
    # Cost for the room
    decimal price;
    # Number of rooms as per the status
    int count;
|};
# Represents a collection of resort rooms
public type Rooms record {|
    *http:Links;
    # Array of rooms
    Room[] rooms;
|};

# Represents rooms be reserved
public type ReserveRoom record {|
    # Unique identification of the room
    string id;
    # Number of rooms
    int count;
|};
# Represents a reservation of rooms
public type Reservation record {|
    # Rooms to be reserved
    ReserveRoom[] reserveRooms;
    # Start date in yyyy-mm-dd
    string startDate;
    # End date in yyyy-mm-dd
    string endDate;
|};
# Represents a receipt for the reservation
public type ReservationReceipt record {|
    *http:Links;
    # Unique identification of the receipt
    string id;
    # Expiry date in yyyy-mm-dd
    string expiryDate;
    # Last updated time stamp
    string lastUpdated;
    # Currency used in price
    string currency;
    # Total payable
    decimal total;
    # Reservation
    Reservation reservation;
    # State of the reservation
    ReservationState state;
|};
# Represents the unexpected error
public type SnowpeakError record {|
    # Error message
    string msg;
|};
# The response for successful reservation update
public type ReservationUpdated record {|
    *http:Ok; 
    # The payload for successful reservation update
    ReservationReceipt body;
|};
# The response for successful reservation creation
public type ReservationCreated record {|
    *http:Created; 
    # The payload for successful reservation creation 
    ReservationReceipt body;
|};
# The response for the unsuccessful reservation creation 
public type ReservationConflict record {|
    *http:Conflict; 
    # The payload for the unsuccessful reservation creation
    SnowpeakError body;
|};
# The response for the successful reservation cancelation 
public type ReservationCanceled record {|
    *http:Ok;
    # The payload for the successful reservation deletion
    ReservationReceipt body;
|};

# Reperesents payement for rooms
public type Payment record {|
    # Name of the card holder
    string cardholderName;
    # Card number
    int cardNumber;
    # Expiration month of the card in mm
    int expiryMonth;
    # Expiaration year of the card in yyyy
    int expiryYear; 
|};

# Reperesents receipt for the payment
public type PaymentReceipt record {|
    *http:Links;
    # Unique identification 
    string id;
    # Currency used in price
    string currency;
    # Total amount paid
    decimal total;
    # Last updated time stamp
    string lastUpdated;
    # Booked rooms
    Room[] rooms;
|};
# The response for the successful payment cration
public type PaymentCreated record {|
    *http:Created;
    # The payload for the successful payment cration
    PaymentReceipt body;
|};
# The response for the unsuccessful payment creation
public type PaymentConflict record {|
    *http:Conflict;
    # The payload for the unsuccessful payment creation
    SnowpeakError body;
|};

# The response for the unexpected error
public type SnowpeakInternalError record {|
    *http:InternalServerError;
    # The payload for the unexpected error
    SnowpeakError body;
|};
