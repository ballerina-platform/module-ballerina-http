# Proposal: Introducing initial support for HATEOAS

_Owners_: @shafreenAnfar @chamil321 @ayeshLK @TharmiganK  
_Reviewers_: @nadeeshaan @chamil321 @TharmiganK    
_Created_: 2022/06/09  
_Updated_: 2022/06/09  
_Issue_: [#2391](https://github.com/ballerina-platform/ballerina-standard-library/issues/2391)

## Summary

Hypermedia As the Engine Of Application State (HATEOAS) is one of the key principles in REST though it is often ignored.
This principle basically talks about the connectedness of resources, creating a Web like experience to REST API users. 
This proposal is to introduce the initial design to support the connectedness of resources. Note that in the rest of the
proposal HATEOAS is referred to as Hypermedia constraint.

## Goals
- Introduce the ability to statically record the connectedness of resources in Ballerina

## Non-Goals
- Introduce the ability to dynamically record the connectedness of resources in Ballerina

## Motivation

Hypermedia constraint is a key principle in REST for a reason. It brings the connectedness to a set of scattered resources.
It also brings direction as to what the user might do next. Similar to Web pages, REST APIs become self-descriptive and
dynamic along with this constraint. Consider the below diagram which represents a set of resources in a resort reservation
API.

![make-a-reservation-states](https://user-images.githubusercontent.com/63336800/173808358-365774ad-fd43-4dd5-82ef-b2bdb9830351.png)

You can see that there is a set of resources but to make sense out of it you have to read some documents related to this 
API. Now consider the same REST API with the Hypermedia constraint applied to it.

![make-a-reservation-state-diagram](https://user-images.githubusercontent.com/63336800/173808478-5e7fefa8-ed59-4847-83ca-d60e7bfada10.png)

Instantly, it changes the outlook of the API. API becomes self-descriptive and easy to make sense. There is no need to 
read another document to understand it. Moving the API close to a Web like experience. There are other benefits that 
comes with this constraint but this proposal focuses on the above.

## Description

In order to get the connectedness of resources as depicted in the second image, it is required to have the below information.

- Resource name
- Resource names of the resources connected to
- Relation (i.e. cancel, edit, payment, etc)

None of this information is captured in the resource signatures at the moment. Therefore, in order to add this 
additional information, `@ResourceConfig` annotation is enriched with the following record and the name field.

```ballerina
string name;
LinkedTo[] linkedTo;

type LinkedTo record {|
    string name;
    string relation = "self"; // Defaulted to the IANA link relation `self`
    string method?;
|};
```
Let's consider the above resort reservation example. As you can see, `locations` resource is connected to the `rooms` resource.
This connection can be captured in the code as follows.

```ballerina
service /snowpeak on new http:Listener(port) {

    @http:ResourceConfig {
        name: "Locations",
        linkedTo: [ {names: "Rooms", relation: "room"} ]
    }
    resource function get locations() returns @http:Cache rep:Locations|rep:SnowpeakInternalError {
       // some logic
    }

    @http:ResourceConfig {
        name: "Rooms"
    }
    resource function get locations/[string id]/rooms(string startDate, string endDate) 
                returns rep:Rooms|rep:SnowpeakInternalError {
        // some logic
    }
}
```
In the case of links pointing to the same resource (same path) as in the `reservation` resource (i.e. edit, cancel), 
resource name can be duplicated. But to resolve conflicts in finding the exact linked resource, the `linkTo` should 
additionally specify the linked resource method.

```ballerina
service /snowpeak on new http:Listener(port) {

    @http:ResourceConfig {
        name: "Reservation",
        linkedTo: [ 
             { names: "Payments", relation: "payment" },
             { names: "Reservations", relation: "edit", method: "put" },
             { names: "Reservations", relation: "cancel", method: "delete" }
        ]
    }
    resource function put reservations/[string id](@http:Payload rep:Reservation reservation) 
                returns rep:ReservationCreated|rep:ReservationConflict|rep:SnowpeakInternalError {
       // some logic
    }

    @http:ResourceConfig {
        name: "Reservation"
    }
    resource function delete reservations/[string id]() returns 
                            rep:ReservationCanceled|rep:SnowpeakInternalError {
        // some logic
    }
    
    @http:ResourceConfig {
        name: "Payment"
    }
    resource function get payments/[string id](@http:Payload rep:Payment payment) 
                returns rep:PaymentCreated|rep:PaymentConflict|rep:SnowpeakInternalError {
        // some logic
    }
}
```
> **Note**: For a particular resource, each of the linked resources should have a unique relation i.e. multiple 
> links with the same relation is not supported.

### Compile-Time
Once this information is captured, it is used to generate the OpenAPI documentation, which includes the additional 
information related to connectedness as default values.

```yaml
Locations:
  required:
    - locations
    - _links
  type: object
  properties:
    locations:
      required:
        - address
        - id
        - name
      type: array
      items:
        name:
          type: string
          description: Name of the location
        id:
          type: string
          description: Unique identification
        address:
          type: string
          description: Address of the location
    _links: 
      type: object
      additionalProperties: 
        required:
          - href
        type: object
        properties:
          rel: 
            type: string
          href: 
            type: string
          methods: 
            type: array
            items:
              type: string
              enum:
                - OPTIONS
                - HEAD
                - PATCH
                - DELETE
                - PUT
                - POST
                - GET
          types:
            type: array
            items:
              type: string
```

### Run-Time
During runtime these static values are used to inject and populate the `http:Link` fields. For instance, if the user 
returns the below record type, the runtime will inject the `http:Link` record as in the latter.

```ballerina
public type Location record {|
    string name;
    string id;
    string address;
|};

public type Locations record {
    Location[] locations;
};
```
```ballerina
public type Locations record {
    *http:Links;
    Location[] locations;
};
```
> **Note**: Following is the definition of http:Link
```ballerina
# Represents a server-provided hyperlink
public type Link record {
    string rel?;
    string href;
    string[] types?;
    Method[] methods?;
};

# Represents available server-provided links
public type Links record {|
    map<Link> _links; // Key is the relation
|};
```

`href` field is filled in as a URL template which matches with the `linkedTo` resource along with the other fields.

Consider the below resource.
```ballerina
@http:ResourceConfig {
    name: "Locations",
    linkedTo: [ {names: "Rooms", relation: "room"} ]
}
resource function get locations() returns rep:Locations|rep:SnowpeakInternalError {
   return {
      locations : [
         {
            name: "Alps",
            id: "l1000",
            address: "NC 29384, some place, switzerland"
         }
      ]
   };
}
```
Final output of the response.
```json
{
    "locations" : [
        {
            "name": "Alps",
            "id": "l1000",
            "address": "NC 29384, some place, switzerland"
        }
    ],
    "_links" : {
        "room": {
            "href": "/snowpeak/locations/{id}/rooms",
            "methods": ["GET"]
        }
    }
}
```

For the non-json payloads the links will be added as `Link` header. Sample `Link` header is given below :
```
link: </snowpeak/locations/{id}/rooms>; rel="room"; methods="\"GET\""
```
> **Note**: The links will not be added either in payload or in header if the resource returns a `http:Response`.

> **Note**: If the links are already added by the user either in the payload or as `Link` header, then the response 
> will not be overwritten by the links generated from `linkedTo` configuration

## Dependencies

Further, as the next step, low code editors can be used to generate the annotation values related to connectedness 
by letting users simply draw the state machine.

Information added to OpenAPI spec can be used to improve the user experience of REST API consumers with better 
tooling as they can have GraphQL like experience.
