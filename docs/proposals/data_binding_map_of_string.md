# Proposal: Data-binding map<string> for application/www-x-form-urlencoded

_Owners_: @shafreenAnfar @chamil321 @ayeshLK @TharmiganK  
_Reviewers_: @shafreenAnfar 
_Created_: 2022/01/12  
_Updated_: 2022/01/12  
_Issue_: [#2526](https://github.com/ballerina-platform/ballerina-standard-library/issues/2526)

## Summary
`application/www-x-form-urlencoded` is common MIME type in use. It allows you to send key/value pairs in the payload.
This proposal is to provide data binding for such payload. Both on listener side as well as the client side.

## Goals
- Improve user experience when dealing with `application/www-x-form-urlencoded`

## Motivation

As mentioned in the summary section `application/www-x-form-urlencoded` is used to send key/value pairs in the 
entity body. However, Ballerina does not provide a direct data binding for such payload. Therefore, users have to 
either do string manipulation or use `http:Request` object's `getFormParams()` function. But it is not the best 
user experience. This is applicable for both the listener side as well as the client side.

User experience can be radically improved by introducing data binding for such payloads as discussed in the next 
section.

## Description

Since `application/www-x-form-urlencoded` is about key/value pairs, the appropriate Ballerina data binding is 
`map<string>`. This is applicable for both listener and client side. However, users could use `map<string>` 
for `json` payloads as well. Following table shows the mapping and the payload.

Ballerina Type | Media Type | Payload
---|---|---
map\<string\> | application/www-x-form-urlencoded | key1=value1&key2=value2
json | application/json | { "key1": "value1", "key2": "value2" }

With this improvement, if the user has provided `map<string>` as the expected type, the HTTP listener and client will
parse the payload according to the `application/www-x-form-urlencoded` content type, decode and return a map of string.

Suppose user wanted the json payload to be mapped to `map<string>`, in such cases, the user has to state the type as 
`json` and process as `map<string>`. Otherwise, it will end up being an error of parsing form data.

### Listener

On the listener side users should be able to do following when dealing with such payload.

```ballerina
service / on new http:Listener(9090) {
    resource function post key\-value(@http:Payload map<string> pairs) returns string {
        // do something
    }
}
```
### Client
On the client side the user experience should be as follows.

```ballerina
http:Client foo = check new("localhost:9090/bar");
map<string> pairs = check foo->get("/zee");
```

### Error handling

1. If the inbound request payload is empty or not available, the listener will result in a 400 BAD REQUEST
2. If the inbound response payload is empty or not available, the client will result in an error. When the type is 
`map<string>?`, then `()` will be returned.
3. Out of the key/value pair, if a value is empty, the map contains the key with an empty value.   
4. Out of the key/value pair, if a key is empty, the map will not contain the key/value.
5. In case of an incompatible payload type, an error is returned.
