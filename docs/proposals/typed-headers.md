# Proposal: Typed headers for HTTP response 

_Owners_: @shafreenAnfar @chamil321 @ayeshLK @TharmiganK  
_Reviewers_: @chamil321  
_Created_: 2022/01/09  
_Updated_: 2022/01/10  
_Issue_: [#2562](https://github.com/ballerina-platform/ballerina-standard-library/issues/2562)  

## Summary

The HTTP standard library provides a specific type for each HTTP response status code. Users can create subtypes using these types by providing their own type for the `body` field but not for the `headers` field. Therefore, the generated OpenAPI specification does not include any header details. This proposal is to allow users to provide their own type for `headers` field as well. 

## Goals
- To be able to include header details of the response when generating OpenAPI specification

## Motivation

As mentioned in the summary, at the moment, when generating OpenAPI specification from a given service, users have no way to include header details into the response. However, in reality, there could be situations where users need to include custom headers in their responses. Therefore, this is a limitation in the current design. 

## Description

OpenAPI specification allows users to include status code details, payload details and header details. In order to include the first two details, the HTTP library has provided typed records for each status code and allow users to create subtypes out of those main types by providing their own type for the `body` field. 

However, this only solves the first two requirements. In order to, add header details users need to be able to create subtypes out of main types by providing their own types for the `header` field. At the moment, this is not possible. Following is the type definition for `http:Ok` main type.

```ballerina
public type Ok record {|
    *CommonResponse;
    readonly StatusOK status = STATUS_OK_OBJ;
|};

public type CommonResponse record {|
    string mediaType?;
    map<string|string[]> headers?;
    anydata body?;
|};
```
> **Note**: Some parts of the type definitions are not included for brevity.

In order to let users have their typed header fields, the `CommonResponse` must be changed as follows.

```ballerina
public type CommonResponse record {|
    string mediaType?;
    map<string|int|boolean|string[]|int[]|boolean[]> headers?;
    anydata body?;
|};
```
That is the only changed required. The initial design only considers `string`, `int` and `boolean`. These types can be extended as needed. 

Now, let's consider an example, say a user wants to send `x-rate-limit-id`,  `x-rate-limit-remaining` and `x-rate-limit-types` in the response. In that case, the user can define his/her own subtype as follows.

```ballerina
public type RateLimitHeaders record {|
    string x\-rate\-limit\-id;
    int x\-rate\-limit\-remaining;
    string[] x\-rate\-limit\-types;
|};

public type OkWithRateLmits record {|
    *Ok;
    RateLimitHeaders headers;
    string body;
|};
```
The defined subtype can be used in the resource as follows.

```ballerina
service / on new http:Listener(9090) {
    resource function get status() returns OkWithRateLmits {
        OkWithRateLmits okWithRateLmits = {
            headers: {
                x\-rate\-limit\-id: "1xed",
                x\-rate\-limit\-remaining: 3,
                x\-rate\-limit\-types: ["sliver", "gold"]
            },
            body: "full"
        };
        return okWithRateLmits;
    }
}
```
> **Note**: It was also considered using the type `record {string|int|boolean|string[]|int[]|boolean[]...;} ` for headers. But because of the limitation where rest field names could only be string literals, it was dropped.  
