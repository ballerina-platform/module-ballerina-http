# Specification: Ballerina HTTP Library

_Owners_: @shafreenAnfar @TharmiganK @ayeshLK @chamil321  
_Reviewers_: @shafreenAnfar @bhashinee @TharmiganK @ldclakmal  
_Created_: 2021/12/23  
_Updated_: 2021/12/23  
_Issue_: [#572](https://github.com/ballerina-platform/ballerina-standard-library/issues/572)


# Introduction
This is the specification for HTTP standard library, which provides HTTP functionalities in the 
[Ballerina programming language](https://ballerina.io/), which is an open-source programming language for the cloud 
that makes it easier to use, combine, and create network services.

# Contents

1. [Overview](#1-overview)
2. [Components](#2-components)
    * 2.1. [Listener](#21-listener)
        * 2.1.1. [Automatically starting the service](#211-automatically-starting-the-service)
        * 2.1.2. [Programmatically starting the service](#212-programmatically-starting-the-service)
    * 2.2. [Service](#22-service)
        * 2.2.1. [Service type](#221-service-type)
        * 2.2.2. [Service-base-path](#222-service-base-path)
        * 2.2.3. [Service declaration](#223-service-declaration)
        * 2.2.4. [Service class declaration](#224-service-class-declaration)
    * 2.3. [Resource](#23-resource)
        * 2.3.1. [Accessor](#231-accessor)
        * 2.3.2. [Resource-name](#232-resource-name)
        * 2.3.3. [Path parameter](#233-path-parameter)
        * 2.3.4. [Return types](#234-return-types)
            * 2.3.4.1. [Caller](#2341-httpcaller)
            * 2.3.4.2. [Request](#2342-httprequest)
            * 2.3.4.3. [Query param](#2343-query-parameter)
            * 2.3.4.4. [Payload param](#2344-payload-parameter)
            * 2.3.4.5. [Header param](#2345-header-parameter)
      * 2.3.5. [Introspection resource](#235-introspection-resource)
    * 2.4. [Client](#24-client)
        * 2.4.1. [Client types](#241-client-types)
            * 2.4.1.1. [Security](#2411-security)
            * 2.4.1.2. [Caching](#2412-caching)
            * 2.4.1.3. [Redirect](#2413-redirect)
            * 2.4.1.4. [Retry](#2414-retry)
            * 2.4.1.5. [Circuit breaker](#2415-circuit-breaker)
            * 2.4.1.6. [Cookie](#2416-cookie)
            * 2.4.1.7. [Load balance](#2417-load-balance)
            * 2.4.1.8. [Failover](#2418-failover)
        * 2.4.2. [Client actions](#242-client-action)
            * 2.4.2.1. [Entity body methods](#2421-entity-body-methods)
            * 2.4.2.2. [Non entity body methods](#2422-non-entity-body-methods)
            * 2.4.2.3. [Forward/execute methods](#2423-forwardexecute-methods)
            * 2.4.2.4. [HTTP2 additional methods](#2424-http2-additional-methods)
        * 2.4.3. [Client actions return types](#243-client-action-return-types)
3. [Request-routing](#3-request-routing)
    * 3.1. [Uri and http method match](#31-uri-and-http-method-match)
    * 3.2. [Most specific path match](#32-most-specific-path-match)
    * 3.3. [Wild card path match](#33-wild-card-path-match)
    * 3.4. [Path parameter template match](#34-path-parameter-template-match)
4. [Annotations](#4-annotations)
    * 4.1. [Service configuration](#41-service-configuration)
    * 4.2. [Resource configuration](#42-resource-configuration)
    * 4.3. [Payload annotation](#43-payload-annotation)
        * 4.3.1. [Payload binding parameter](#431-payload-binding-parameter)
        * 4.3.2. [Anydata return value info](#432-anydata-return-value-info)
    * 4.4. [Callerinfo annotation](#44-callerinfo-annotation)
    * 4.5. [Header annotation](#45-header-annotation)
    * 4.6. [Cache config annotation](#46-cache-config-annotation)
5. [url-parameters](#5-url-parameters)
    * 5.1. [Path](#51-path)
    * 5.2. [Query](#52-query)
    * 5.3. [Matrix](#53-matrix)
6. [Request and Response](#6-request-and-response)
7. [Header and Payload](#7-header-and-payload)
    * 7.1. [Parse header functions](#71-parse-header-functions)
8. [Interceptor and error handling](#8-interceptor-and-error-handling)
    * 8.1. [Interceptor](#81-interceptor)
        * 8.1.1. [Request interceptor](#811-request-interceptor)
            * 8.1.1.1. [Request context](#8111-requestcontext)
            * 8.1.1.2. [Next method](#8112-next-method)
            * 8.1.1.3. [Returning error](#8113-returning-error)
        * 8.1.2. [Request error interceptor](#812-request-error-interceptor)
        * 8.1.3. [Engaging interceptor](#813-engaging-interceptors)
            * 8.1.3.1. [Service level](#8131-service-level)
            * 8.1.3.2. [Listener level](#8132-listener-level)
            * 8.1.3.3. [Execution order of interceptors](#8133-execution-order-of-interceptors)
        * 8.1.4. [Data binding](#814-data-binding)
        * 8.1.5. [Return to respond](#815-return-to-respond)
     * 8.2. [Error handling](#82-error-handling)
        * 8.2.1. [Trace log](#821-trace-log)
        * 8.2.2. [Access log](#822-access-log)
9. [Security](#9-security)
    * 9.1. [Authentication and Authorization](#91-authentication-and-authorization)
        * 9.1.1. [Declarative Approach](#911-declarative-approach)
            * 9.1.1.1. [Listener - File User Store](#9111-listener---file-user-store)
            * 9.1.1.2. [Listener - LDAP User Store](#9112-listener---ldap-user-store)
            * 9.1.1.3. [Listener - JWT](#9113-listener---jwt)
            * 9.1.1.4. [Listener - OAuth2](#9114-listener---oauth2)
            * 9.1.1.5. [Client - Basic Auth](#9115-client---basic-auth)
            * 9.1.1.6. [Client - Bearer Token Auth](#9116-client---bearer-token-auth)
            * 9.1.1.7. [Client - Self Signed JWT Auth](#9117-client---self-signed-jwt)
            * 9.1.1.8. [Client - Bearer Token OAuth2](#9118-client---bearer-token-oauth2)
            * 9.1.1.9. [Client - Grant Types OAuth2](#9119-client---grant-types-oauth2)
        * 9.1.2 [Imperative Approach](#912-imperative-approach)
            * 9.1.2.1. [Listener - File User Store](#9121-listener---file-user-store)
            * 9.1.2.2. [Listener - LDAP User Store](#9122-listener---ldap-user-store)
            * 9.1.2.3. [Listener - JWT](#9123-listener---jwt)
            * 9.1.2.4. [Listener - OAuth2](#9124-listener---oauth2)
            * 9.1.2.5. [Client - Basic Auth](#9125-client---basic-auth)
            * 9.1.2.6. [Client - Bearer Token Auth](#9126-client---bearer-token-auth)
            * 9.1.2.7. [Client - Self Signed JWT Auth](#9127-self-signed-jwt)
            * 9.1.2.8. [Client - Bearer Token OAuth2](#9128-client---bearer-token-oauth2)
            * 9.1.2.9. [Client - Grant Types OAuth2](#9129-client---grant-types-oauth2)
   * 9.2. [SSL/TLS and Mutual SSL](#92-ssltls-and-mutual-ssl)
        * 9.2.1. [Listener - SSL/TLS](#921-listener---ssltls)
        * 9.2.2. [Client - Mutual SSL](#922-listener---mutual-ssl)
        * 9.2.3. [Listener - SSL/TLS](#923-client---ssltls)
        * 9.2.4. [Client - Mutual SSL](#924-client---mutual-ssl)
10. [Protocol-upgrade](#10-protocol-upgrade)
    * 10.1. [HTTP2](#101-http2)
        * 10.1.1. [Push promise and promise response](#1011-push-promise-and-promise-response)

## 1. Overview
This specification elaborates on Basic Auth authentication and authorization for all the Ballerina listeners and
clients. The HTTP, gRPC, GraphQL, WebSocket, WebSub protocol-based listeners and clients are secured according to this
specification.

The ballerina language provides the first class support for writing network oriented programming models in a more 
initiative manner. The ballerina-http standard library consumes the rich language construct and creates the 
programming model to write services.

The HTTP standard library is designed to work with HTTP protocol. It includes high level abstractions such as 
`http:Request`, `http:Response`, `http:Service` and `http:Client` which allow users to consume and produce HTTP 
services. Further the users can use this library to build other libraries. In fact, the standard libraries such 
as GraphQL, Websub and WebSubHub use this library internally.

In addition to functional requirements, this library deals with none functional requirements such as security,
observability and resiliency. Each requirement is discussed in detail in the coming sections.

## 2. Components
### 2.1. Listener
The HTTP listener object receives network data from a remote process according to the HTTP transport protocol and 
translates the received data into invocations on the resources functions of services that have been 
attached to the listener object. The listener provides the interface between network and services.

As defined in [Ballerina 2021R1 Section 5.7.4](https://ballerina.io/spec/lang/2021R1/#section_5.7.4) the Listener has 
the object constructor and life cycle methods such as attach(), detach(), 'start(), gracefulStop(), and immediateStop().

#### 2.1.1. Automatically starting the service
If a service is attached to the listener, then the listener starts listening on the given port after executing 
attach() and start() methods. HTTP listener can be declared as follows honoring to the generic 
[listener declaration](https://ballerina.io/spec/lang/2021R1/#section_8.3.1)

```ballerina
// Listener object constructor
listener http:Listener serviceListener = new(9090);
```
```ballerina
// Service attaches to the Listener
service http:Service /foo/bar on serviceListener {
    resource function get sayHello(http:Caller caller) {}
}
```

#### 2.1.2. Programmatically starting the service

Users can programmatically start the listener by calling each lifecycle method as follows.

```ballerina
public function main() {
    // Listener object constructor
    listener http:Listener serviceListener = new(9090);
    
    error? err1 = serviceListener.attach(s, “/foo/bar”);
    error? err2 = serviceListener.start();
    //...
    error? err3 = serviceListener.gracefulStop();
}

http:Service s = service object {
    resource function get sayHello(http:Caller caller) {}
}
```

### 2.2. Service
Service is a collection of resources functions, which are the network entry points of a ballerina program. 
In addition to that a service can contain public and private functions which can be accessed by calling with `self`.

#### 2.2.1. Service type
```ballerina
public type Service distinct service object {

};
```
Above distinct type is provided by HTTP module and user can include the type as `*http:Service` to refer it.
The comprehensive typing support is yet to be added to the language. Until that, the compiler plugin is used to 
validate the services.

#### 2.2.2. Service base path

The base path is considered during the request dispatching to discover the service. Identifiers and string literals
are allowed to be stated as base path and it should be started with `/`. The base path is optional and it will be 
default to `/` when not defined. If the base path contains any special characters, those should be escaped or defined
as string literals

```ballerina
service hello\-world new http:Listener(9090) {
   resource function get foo() {

   }
}

service http:Service "hello-world" new http:Listener(9090) {
   resource function get foo() {

   }
}
```

A service can be declared in three ways upon the requirement.

#### 2.2.3. Service declaration
The [Service declaration](https://ballerina.io/spec/lang/2021R1/#section_8.3.2) is a syntactic sugar for creating a
service and it is the mostly used approach for creating a service. The declaration gets desugared into creating a 
listener object, creating a service object, attaching the service object to the listener object.

```ballerina
service http:Service /foo/bar on new http:Listener(9090) {
  resource function get greeting() returns string {
      return "hello world";
  }
}
```

#### 2.2.4. Service class declaration

The service value can be instantiated using the service class. This way, user has the completed control of attaching
the service to the listener. The life cycle methods to used to proceed.

```ballerina
service isolated class SClass {
   *http:Service;
   resource function get greeting() returns string {
       return "hello world";
   }
}

public function main() returns error? {
   http:Listener serviceListener = check new (9090);
   http:Service httpService = new SClass();
   
   error? err1 = serviceListener.attach(httpService, ["foo", "bar"]);
   error? err2 = serviceListener.'start();
   runtime:registerListener(serviceListener);
}
```

#### 2.2.5. Service constructor expression

```ballerina
listener http:Listener serviceListener = new (9090);

http:Service httpService = @http:ServiceConfig {} service object {
   resource function get greeting() returns string {
       return "hello world";
   }
};

public function main() {
   error? err1 = serviceListener.attach(httpService, "/foo/bar");
   error? err2 = serviceListener.start();
   runtime:registerListener(serviceListener);
}
```

### 2.3. Resource

A method of a service can be declared as a [resource function](https://ballerina.io/spec/lang/2021R1/#resources) 
which is associated with configuration data that is invoked by a network message by a Listener. Users write the 
business logic inside a resource and expose it over the network.

#### 2.3.1. Accessor
The accessor-name of the resource represents the HTTP method and it can be get, post, put, delete, head, patch, options 
and default. If the accessor is unmatched, 405 Method Not Allowed response is returned. When the accessor name is 
stated as default, any HTTP method can be matched to it in the absence of an exact match. Users can define custom 
methods such as copy, move based on their requirement. A resource which can handle any method would look like as 
follows. This is useful when handling unmatched verbs.

```ballerina
resource function 'default NAME_TEMPLATE () {
    
}
```
#### 2.3.2. Resource name
The resource-name represents the path of the resource which is considered during the request dispatching. The name can 
be hierarchical(foo/bar/baz). Each path identifier should be separated by `/` and first path identifier should not 
contain a prefixing `/`. If the paths are unmatched, 404 NOT FOUND response is returned.
```ballerina
resource function post hello() {
    
}
```
Only the identifiers can be used as resource path not string literals. Dot identifier is 
used to denote the `/` only if the path contains a single identifier. 
```ballerina
resource function post .() {
    
}
```
Any special characters can be used in the path by escaping.
```ballerina
resource function post hello\-world() {
    
}
```

#### 2.3.3. Path parameter
The path parameter segment is also a part of the resource name which is declared within brackets along with the type. 
As per the following resource name, baz is the path param segment and it’s type is string. Like wise users can define 
string, int, boolean, float, and decimal typed path parameters. If the paths are unmatched, 404 NOT FOUND response 
is returned. If the segment failed to parse into the expected type, 500 Internal Server Error response is returned.

```ballerina
resource function post foo/bar/[string baz]/qux() {
    // baz is the path param
}

resource function get data/[int age]/[string name]/[boolean status]/[float weight]() returns json {
   int balAge = age + 1;
   float balWeight = weight + 2.95;
   string balName = name + " lang";
   if (status) {
       balName = name;
   }
   json responseJson = { Name:name, Age:balAge, Weight:balWeight, Status:status, Lang: balName};
   return responseJson;
}
```

If multiple path segments needs to be matched after the last identifier, Rest param should be used at the end of the 
resource name as the last identifier. string, int, boolean, float, and decimal types are supported as rest parameters.
```ballerina
resource function get foo/[string... bar]() returns json {
   json responseJson = {"echo": bar[0]};
   return responseJson;
}
```

Using both `'default` accessor and the rest parameters, a default resource can be defined to a service. This 
default resource can act as a common destination where the unmatched requests (either HTTP method or resource path) may 
get dispatched.

```ballerina
resource function 'default [string... s]() {

}
```

#### 2.3.4. Signature parameters
The resource function can have the following parameters in the signature. There are no any mandatory params or any 
particular order. But it’s a good practice to keep the optional param at the end.

```ballerina
resource function XXX NAME_TEMPLATE ([http:Caller hc], [http:Request req], (anydata queryParam)?, 
    (@http:Payload anydata payload)?, (@http:Header string header)?, (http:Header headers)? ) {
        
}
```

However, the first choice should be to use signature params and use returns. Avoid caller unless you have specific 
requirement. Also use data binding, header params and resource returns to write smaller code with more readability.

##### 2.3.4.1. http:Caller

The caller client object represents the endpoint which initiates the request. Once the request is processed, the 
corresponding response is sent back using the remote functions which are associated with the caller object. 
In addition to that, the caller has certain meta information related to remote and local host such as IP address,
protocol. This parameter is not compulsory and not ordered.


The callerInfo annotation associated with the `Caller` is to denote the response type.
It will ensure that the resource function responds with the right type and provides static type information about 
the response type that can be used to generate OpenAPI.

The default type is the `http:Response`. Other than that, caller remote functions will accept following types as the 
outbound response payload. Internally an `http:Response` is created including the given payload value

```ballerina
string|xml|json|byte[]|int|float|decimal|boolean|map<json>|table<map<json>>|(map<json>|table<map<json>>)[]|
mime:Entity[]|stream<byte[], io:Error?>|()
```

Based on the payload types respective header value is added as the `Content-type` of the `http:Response`.

 Type|Content Type
---|---
() | -
string | text/plain
xml | application/xml
byte[], stream<byte[], io:Error?> | application/octet-stream
int, float, decimal, boolean | application/json
map\<json\>, table<map\<json\>>, map\<json\>[], table<map\<json\>>)[] | application/json

The HTTP compiler extension checks the argument of the `respond()` method if the matching payload type is passed as
denoted in the CallerInfo annotation

```ballerina
resource function post foo(@http:CallerInfo {respondType:Person}  http:Caller hc) {
    Person p = {};
    hc->respond(p);
}
```
##### 2.3.4.2. http:Request

The `http:Request` represents the request which is sent and received over the network which includes headers and 
the entity body. Listener passes it to the resource function as an argument to be accessed by the user based on 
their requirement. This parameter is not compulsory and not ordered.

```ballerina
resource function get person(http:Request req) {
    
}
```

See section [Request and Response] to find out more. 

##### 2.3.4.3. Query parameter

The query param is a URL parameter which is available as a resource function parameter and it's not associated 
with any annotation or additional detail. This parameter is not compulsory and not ordered. The type of query param 
are as follows

```ballerina
type BasicType boolean|int|float|decimal|string|map<json>;
public type QueryParamType ()|BasicType|BasicType[];
```

The same query param can have multiple values. In the presence of multiple such values,  If the user has specified 
the param as an array type, then all values will return. If not the first param values will be returned. As per the 
following resource function, the request may contain at least two query params with the key of bar and id.
Eg : “/hello?bar=hi&id=56”

```ballerina
resource function get hello(string bar, int id) { 
    
}
```

If the query parameter is not defined in the function signature, then the query param binding does not happen. If a 
query param of the request URL has no corresponding parameter in the resource function, then that param is ignored. 
If the parameter is defined in the function, but there is no such query param in the URL, that request will lead 
to a 400 BAD REQUEST error response unless the type is nilable (string?)

The query param consists of query name and values. Sometimes user may send query without value(`foo:`). In such
situations, when the query param type is nilable, the values returns nil and same happened when the complete query is
not present in the request. In order to avoid the missing detail, a service level configuration has introduced naming
`treatNilableAsOptional`

```ballerina
@http:ServiceConfig {
    treatNilableAsOptional : false
}
service /queryparamservice on QueryBindingIdealEP {

    resource function get test1(string foo, int bar) returns json {
        json responseJson = { value1: foo, value2: bar};
        return responseJson;
    }
}
```

<table>
<tr>
<th> Case </th>
<th>  Resource argument </th>
<th>  Query </th>
<th>  Current Mapping (treatNilableAsOptional=true - Default) </th>
<th>  Ideal Mapping (treatNilableAsOptional=false) </th>
</tr>
<tr>
<td rowspan=4> 1 </td>
<td rowspan=4> string foo </td>
<td> foo=bar </td>
<td> bar </td>
<td> bar </td>
</tr>
<tr>
<td> foo=</td>
<td> "" </td>
<td> "" </td>
</tr>
<tr>
<td> foo</td>
<td> Error : no query param value found for 'foo' </td>
<td> Error : no query param value found for 'foo' </td>
</tr>
<tr>
<td> No query</td>
<td> Error : no query param value found for 'foo' </td>
<td> Error : no query param value found for 'foo' </td>
</tr>
<tr>
<td rowspan=4> 2 </td>
<td rowspan=4> string? foo </td>
<td> foo=bar </td>
<td> bar </td>
<td> bar </td>
</tr>
<tr>
<td> foo=</td>
<td> "" </td>
<td> "" </td>
</tr>
<tr>
<td> foo</td>
<td> nil </td>
<td> nil </td>
</tr>
<tr>
<td> No query</td>
<td> nil </td>
<td> Error : no query param value found for 'foo' </td>
</tr>
</table>

See section [Query] to understand accessing query param via the request object.

##### 2.3.4.4. Payload parameter

The payload parameter eases access of request payload during the resource invocation. When the payload param is 
defined with @http:Payload annotation, the listener binds the inbound request payload into the param type and return. 
The type of payload param are as follows

```ballerina
string|json|map<json>|xml|byte[]|record {| anydata...; |}|record {| anydata...; |}[]
```

The payload binding process begins soon after the finding the correct resource for the given URL and before the 
resource execution. The error which may occur during the process will be returned to the caller with the response 
status code of 400 BAD REQUEST. The successful binding will proceed the resource execution with the built payload.

```ballerina
resource function post hello(@http:Payload json payload) { 
    
}
```

Internally the complete payload is built, therefore the application should have sufficient memory to support the 
process. Payload binding is not recommended if the service behaves as a proxy/pass-through where request payload is 
not accessed.

User may specify the expected content type in the annotation to shape the resource as described in section [Payload 
binding parameter]

##### 2.3.4.5. Header parameter

The header parameter is to access the inbound request headers The header param is defined with `@http:Header` annotation
The type of header param can be either string or string[]. When multiple header values are present for the given header,
the first header value is returned when the param type is `string`. To retrieve all the values, use `string[]` type.
This parameter is not compulsory and not ordered. 

The header param name is considered as the header name during the value retrieval. However, the header annotation name 
field can be used to define the header name whenever user needs some different variable name for the header. 

User cannot denote the type as a union of both `string` and `string[]`, that way the resource cannot infer a single 
type to proceed. Hence, returns a compiler error.

In the absence of a header when the param is defined in the resource signature, listener returns 400 BAD REQUEST unless
the type is nilable. 

```ballerina
//Single header value extraction
resource function post hello1(@http:Header string referer) {
    
}

//Multiple header value extraction
resource function post hello2(@http:Header {name: "Accept"} string[] accept) {
    
}
```

If the requirement is to access all the header of the inbound request, it can be achieved through the `http:Headers` 
typed param in the signature. It does not need the annotation and not ordered.

```ballerina
resource function get hello3(http:Headers headers) {
   String|error referer = headers.getHeader("Referer");
   String[]|error accept = headers.getHeaders("Accept");
   String[] keys = headers.getHeaderNames();
}
```

The header consists of header name and values. Sometimes user may sent header without value(`foo:`). In such 
situations, when the header param type is nilable, the values returns nil and same happened when the complete header is 
not present in the request. In order to avoid the missing detail, a service level configuration has introduced naming 
`treatNilableAsOptional`

```ballerina
@http:ServiceConfig {
    treatNilableAsOptional : false
}
service /headerparamservice on HeaderBindingIdealEP {

    resource function get test1(@http:Header string? foo) returns json {
        
    }
}
```

<table>
<tr>
<th>  Case </th>
<th>  Resource argument </th>
<th>  Header </th>
<th>  Current Mapping (treatNilableAsOptional=true - Default) </th>
<th>  Ideal Mapping (treatNilableAsOptional=false) </th>
</tr>
<tr>
<td rowspan=3> 1 </td>
<td rowspan=3> string foo </td>
<td> foo:bar </td>
<td> bar </td>
<td> bar </td>
</tr>
<tr>
<td> foo:</td>
<td> Error : no header value found for 'foo' </td>
<td> Error : no header value found for 'foo' </td>
</tr>
<tr>
<td> No header</td>
<td> Error : no header value found for 'foo' </td>
<td> Error : no header value found for 'foo' </td>
</tr>
<tr>
<td rowspan=3> 2 </td>
<td rowspan=3> string? foo </td>
<td> foo:bar </td>
<td> bar </td>
<td> bar </td>
</tr>
<tr>
<td> foo:</td>
<td> nil </td>
<td> nil </td>
</tr>
<tr>
<td> No header</td>
<td> nil </td>
<td> Error : no header value found for 'foo' </td>
</tr>
</table>


#### 2.3.4. Return types
The resource function supports anydata, error?, http:Response and http:StatusCodeResponse as return types. 
Whenever user returns a particular output, that will result in an HTTP response to the caller who initiated the 
call. Therefore, user does not necessarily depend on the `http:Caller` and its remote methods to proceed with the 
response. 

```ballerina
resource function XXX NAME_TEMPLATE () returns @http:Payload anydata|http:Response|http:StatusCodeResponse|http:Error? {
}
```

In addition to that the `@http:Payload` annotation can be specified along with anydata return type
mentioning the content type of the outbound payload.

```ballerina
resource function get test() returns @http:Payload {mediaType:"text/id+plain"} string {
    return "world";
}
```

Based on the return types respective header value is added as the `Content-type` of the `http:Response`. 

Type|Content Type
---|---
() | -
string | text/plain
xml | application/xml
byte[]| application/octet-stream
int, float, decimal, boolean | application/json
map\<json\>, table<map\<json\>>, map\<json\>[], table<map\<json\>>)[] | application/json
http:StatusCodeResponse | application/json

#### 2.3.4.1. Status Code Response

The status code response records are defined in the HTTP module for every HTTP status code. It improves readability & 
helps OpenAPI spec generation. 

```ballerina
type Person record {
   string name;
};
resource function put person(string name) returns record {|*http:Created; Person body;|} {
   Person person = {name:name};
   return {
       mediaType: "application/person+json",
       headers: {
           "X-Server": "myServer"
       },
       body: person
   };
}
```

Following is the `http:Ok` definition. Likewise all the status codes are provided.

```ballerina
public type Ok record {
   readonly StatusOk status;
   string mediaType;
   map<string|string[]> headers?;
   anydata body?;
};

resource function get greeting() returns http:Ok|http:InternalServerError {
   http:Ok ok = { body: "hello world", headers: { xtest: "foo"} };
   return ok;
}
```

#### 2.3.4.2. Return nil

Return nil from the resource has few meanings. 

1. If the resource wants to return nothing, the listener will return 202 ACCEPTED response.
```ballerina
resource function post person(@http:Payload Person p) {
    int age = p.age;
    io:println(string `Age is: ${age}`);
}
```   
2. If the resource is dealt with the response via http:Caller, then returning () does not lead to subsequent response. 
   Listener aware that the request is already being served.
```ballerina
resource function get fruit(string? colour, http:Caller caller) {
    if colour == "red" {
        error? result = caller->respond("Sending apple");
        return; // ending the flow, so not 202 response
    }
    error? result = caller->respond("Sending orange");
}
```   
3. If the resource is dealt with the success response via http:Caller and return () in the else case, then the 
   response is 500 INTERNAL SERVER ERROR.
```ballerina
resource function get fruit(string? colour, http:Caller caller) {
    if colour == "red" {
        error? result = caller->respond("Sending apple");
        return; // ending the flow
    }
    return; // 500 internal Server Error
}
```
#### 2.3.5. Introspection resource

The introspection resource is internally generated for each service and host the openAPI doc can be generated 
(or retrieved) at runtime when requested from the hosted service itself. In order to get the openAPI doc hosted
resource path, user can send an OPTIONS request either to one of the resources or the service. The link header
in the 204 response specifies the location. Then user can send a GET request to the dynamically generated URL in the 
link header with the relation openapi to get the openAPI definition for the service.

Sample service
```ballerina
import ballerina/http;

service /hello on new http:Listener(9090) {
    resource function get greeting() returns string{
        return "Hello world";
    }
}
```

Output of OPTIONS call to usual resource
```ballerina
curl -v localhost:9090/hello/greeting -X OPTIONS
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 9090 (#0)
> OPTIONS /hello/greeting HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.64.1
> Accept: */*
> 
< HTTP/1.1 204 No Content
< allow: GET, OPTIONS
< link: </hello/openapi-doc-dygixywsw>;rel="service-desc"
< server: ballerina/2.0.0-beta.2.1
< date: Wed, 18 Aug 2021 14:09:40 +0530
< 
```

Output of GET call to introspection resource
```ballerina
curl -v localhost:9090/hello/openapi-doc-dygixywsw
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 9090 (#0)
> GET /hello/openapi-doc-dygixywsw HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.64.1
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-type: application/json
< content-length: 634
< server: ballerina/2.0.0-beta.2.1
< date: Wed, 18 Aug 2021 14:22:29 +0530
< 
{
  "openapi": "3.0.1",
  "info": {
     "title": " hello",
     "version": "1.0.0"
  },
  "servers": [
     {
        "url": "localhost:9090/hello"
     }
  ],
  "paths": {
     "/greeting": {
        "get": {
           "operationId": "operation1_get_/greeting",
           "responses": {
              "200": {
                 "description": "Ok",
                 "content": {
                    "text/plain": {
                       "schema": {
                          "type": "string"
                       }
                    }
                 }
              }
           }
        }
     }
  },
  "components": {}
}
```

Output of OPTIONS call to service base path

```ballerina
curl -v localhost:9090/hello -X OPTIONS 
*   Trying ::1...
* TCP_NODELAY set
* Connected to localhost (::1) port 9090 (#0)
> OPTIONS /hello HTTP/1.1
> Host: localhost:9090
> User-Agent: curl/7.64.1
> Accept: */*
> 
< HTTP/1.1 204 No Content
< allow: GET, OPTIONS
< link: </hello/openapi-doc-dygixywsw>;rel="service-desc"
< server: ballerina/2.0.0-beta.2.1
< date: Thu, 19 Aug 2021 13:47:29 +0530
< 
* Connection #0 to host localhost left intact
* Closing connection 0
```

### 2.4. Client
A client allows the program to send network messages to a remote process according to the HTTP protocol. The fixed 
remote functions of the client object correspond to distinct network operations defined by the HTTP protocol.

The client init function requires a valid URL and optional configuration to initialize the client. 
```ballerina
http:Client clientEP = check new ("http://localhost:9090", { httpVersion: "2.0" });
```

#### 2.4.1 Client types
The client configuration can be used to enhance the client behaviour.

```ballerina
public type ClientConfiguration record {|
    string httpVersion = HTTP_1_1;
    ClientHttp1Settings http1Settings = {};
    ClientHttp2Settings http2Settings = {};
    decimal timeout = 60;
    string forwarded = "disable";
    FollowRedirects? followRedirects = ();
    PoolConfiguration? poolConfig = ();
    CacheConfig cache = {};
    Compression compression = COMPRESSION_AUTO;
    ClientAuthConfig? auth = ();
    CircuitBreakerConfig? circuitBreaker = ();
    RetryConfig? retryConfig = ();
    CookieConfig? cookieConfig = ();
    ResponseLimitConfigs responseLimits = {};
    ClientSecureSocket? secureSocket = ();
|};
```

Based on the config, the client object will be accompanied by following client behaviours. Following clients cannot be
instantiated calling `new`, instead user have to enable the config in the `ClientConfiguration`.

##### 2.4.1.1 Security 
Provides secure HTTP remote functions for interacting with HTTP endpoints. This will make use of the authentication
schemes configured in the HTTP client endpoint to secure the HTTP requests.
```ballerina
http:Client clientEP = check new("https://localhost:9090",
    auth = {
        username: username,
        password: password
    },
    secureSocket = {
        cert: {
            path: TRUSTSTORE_PATH,
            password: "ballerina"
        }
    }
);
```

##### 2.4.1.2 Caching
An HTTP caching client uses the HTTP caching layer once `cache` config is enabled.
```ballerina
http:Client clientEP = check new("http://localhost:9090",
    cache = {
        enabled: true, 
        isShared: true 
    }
);
```

##### 2.4.1.3 Redirect
Provide the redirection support for outbound requests internally considering the location header when `followRedirects`
configs are defined.
```ballerina
http:Client clientEP = check new("http://localhost:9090", 
    followRedirects = { 
        enabled: true, 
        maxCount: 3 
    }
);
```

##### 2.4.1.4 Retry
Provides the retrying over HTTP requests when `retryConfig` is defined.
```ballerina
http:Client clientEP = check new("http://localhost:9090",
    retryConfig = {
        interval: 3,
        count: 3,
        backOffFactor: 0.5
    }
);
```

##### 2.4.1.5 Circuit breaker
A Circuit Breaker implementation which can be used to gracefully handle network failures.
```ballerina
http:Client clientEP = check new("http://localhost:9090", 
    circuitBreaker = {
        rollingWindow: {
            timeWindow: 60,
            bucketSize: 20,
            requestVolumeThreshold: 0
        },
        failureThreshold: 0.3,
        resetTime: 2,
        statusCodes: [500, 501, 502, 503]
    }
);
```

##### 2.4.1.6 Cookie
Provides the cookie functionality across HTTP client actions. The support functions defined in the request can be 
used to manipulate cookies.
```ballerina
http:Client clientEP = check new("http://localhost:9090", 
    cookieConfig = { 
        enabled: true, 
        persistentCookieHandler: myPersistentStore 
    }
);
```

Following clients can be created separately as it requires different configurations.

##### 2.4.1.7 Load balance
LoadBalanceClient endpoint provides load balancing functionality over multiple HTTP clients. It uses the
LoadBalanceClientConfiguration. 
```ballerina
public type LoadBalanceClientConfiguration record {|
    *CommonClientConfiguration;
    TargetService[] targets = [];
    LoadBalancerRule? lbRule = ();
    boolean failover = true;
|};

http:LoadBalanceClient clientEP = check new(
    targets = [
        { url: "http://localhost:8093/LBMock1" },
        { url: "http://localhost:8093/LBMock2" },
        { url: "http://localhost:8093/LBMock3" }
    ],
    timeout = 5
);
```

##### 2.4.1.8 Failover
An HTTP client endpoint which provides failover support over multiple HTTP clients. It uses the
FailoverClientConfiguration.
```ballerina
public type FailoverClientConfiguration record {|
    *CommonClientConfiguration;
    TargetService[] targets = [];
    int[] failoverCodes = [501, 502, 503, 504];
    decimal interval = 0;
|};

http:FailoverClient foBackendEP00 = check new(
    timeout = 5,
    failoverCodes = [501, 502, 503],
    interval = 5,
    targets = [
        { url: "http://localhost:3467/inavalidEP" },
        { url: "http://localhost:8080/echo00" },
        { url: "http://localhost:8080/mockResource" },
        { url: "http://localhost:8080/mockResource" }
    ]
)
```
##### 2.4.2. Client action

The HTTP client contains separate remote function representing each HTTP method such as `get`, `put`, `post`,
`delete`,`patch`,`head`,`options` and some custom remote functions.

###### 2.4.2.1 Entity body methods
 
POST, PUT, DELETE, PATCH methods are considered as entity body methods. These remote functions contains RequestMessage
as the second parameter to send out the Request or Payload. 

```ballerina
public type RequestMessage Request|string|xml|json|byte[]|int|float|decimal|boolean|map<json>|table<map<json>>|
                           (map<json>|table<map<json>>)[]|mime:Entity[]|stream<byte[], io:Error?>|();
```

Based on the payload types respective header value is added as the `Content-type` of the `http:Request`.

Type|Content Type
---|---
() | -
string | text/plain
xml | application/xml
byte[], stream<byte[], io:Error?> | application/octet-stream
int, float, decimal, boolean | application/json
map\<json\>, table<map\<json\>>, map\<json\>[], table<map\<json\>>)[] | application/json

The header map and the mediaType param are optional for entity body remote functions.

```ballerina
# The post() function can be used to send HTTP POST requests to HTTP endpoints.
remote isolated function post(string path, RequestMessage message, map<string|string[]>? headers = (),
        string? mediaType = (), TargetType targetType = <>)
        returns targetType|ClientError;

# The put() function can be used to send HTTP PUT requests to HTTP endpoints.
remote isolated function put(string path, RequestMessage message, map<string|string[]>? headers = (),
        string? mediaType = (), TargetType targetType = <>)
        returns targetType|ClientError;

# The patch() function can be used to send HTTP PATCH requests to HTTP endpoints.
remote isolated function patch(string path, RequestMessage message, map<string|string[]>? headers = (),
        string? mediaType = (), TargetType targetType = <>)
        returns targetType|ClientError;

# The delete() function can be used to send HTTP DELETE requests to HTTP endpoints.
remote isolated function delete(string path, RequestMessage message = (), map<string|string[]>? headers = (),
        string? mediaType = (), TargetType targetType = <>)
        returns targetType|ClientError;
```

```ballerina
http:Client httpClient = check new ("https://www.example.com");
string response = check httpClient->post("/some/endpoint",
   {
       name: "foo",
       age: 25,
       address: "area 51"
   },
   headers = {
       "my-header": "my-header-value"
   }
   mediaType = "application/json",
);
```

###### 2.4.2.2 Non Entity body methods

GET, HEAD, OPTIONS methods are considered as non entity body methods. These remote functions does not contains 
RequestMessage, but the header map an optional param.


```ballerina
# The head() function can be used to send HTTP HEAD requests to HTTP endpoints.
remote isolated function head(string path, map<string|string[]>? headers = ()) returns Response|ClientError;

# The get() function can be used to send HTTP GET requests to HTTP endpoints.
remote isolated function get( string path, map<string|string[]>? headers = (), TargetType targetType = <>)
        returns  targetType|ClientError;

# The options() function can be used to send HTTP OPTIONS requests to HTTP endpoints.
remote isolated function options( string path, map<string|string[]>? headers = (), TargetType targetType = <>)
        returns  targetType|ClientError;
```

````ballerina
http:Client httpClient = check new ("https://www.example.com");
map<string|string[]> headers = {
   "my-header": "my-header-value",
   "header-2": ["foo", "bar"]
};
string resp = check httpClient->get("/data", headers);
````

###### 2.4.2.3 Forward/Execute methods

In addition to the standard HTTP methods, `forward` function can be used to proxy an inbound request using the incoming 
HTTP request method. Also `execute` remote function is useful to send request with custom HTTP verbs such as `move`, 
`copy`, ..etc.


```ballerina
# Invokes an HTTP call with the specified HTTP verb.
remote isolated function execute(string httpVerb,  string path, RequestMessage message, 
        map<string|string[]>? headers = (), string? mediaType = (), TargetType targetType = <>)
        returns targetType|ClientError;

# The forward() function can be used to invoke an HTTP call with inbound request's HTTP verb
remote isolated function forward(string path, Request request, TargetType targetType = <>)
        returns  targetType|ClientError;
```

###### 2.4.2.4 HTTP2 additional methods
Following are the HTTP2 client related additional remote functions to deal with promises and responses.

```ballerina

# Submits an HTTP request to a service with the specified HTTP verb.
# The submit() function does not give out a http:Response as the result.
# Rather it returns an http:HttpFuture which can be used to do further interactions with the endpoint.
remote isolated function submit(string httpVerb, string path, RequestMessage message)
    returns HttpFuture|ClientError;

# Passes the request to actual network call.
remote isolated function getResponse(HttpFuture httpFuture) returns Response|ClientError;

# Passes the request to actual network call.
remote isolated function hasPromise(HttpFuture httpFuture) returns boolean;

# Passes the request to actual network call.
remote isolated function getNextPromise(HttpFuture httpFuture) returns PushPromise|ClientError;

# Passes the request to an actual network call.
remote isolated function getPromisedResponse(PushPromise promise) returns Response|ClientError;

# Passes the request to actual network call.
remote isolated function rejectPromise(PushPromise promise);
```

##### 2.4.3. Client action return types

The HTTP client remote function supports the contextually expected return types. The client operation is able to 
infer the expected payload type from the LHS variable type. This is called as client payload binding support where the 
inbound response payload is accessed and parse to the expected type in the method signature. It is easy to access the
payload directly rather manipulation `http:Response` using its support methods such as `getTextPayload()`, ..etc.

Followings are the possible return types:

```ballerina
Response|string|xml|json|map<json>|byte[]|record {| anydata...; |}|record {| anydata...; |}[];
```
```ballerina
http:Client httpClient = check new ("https://person.free.beeceptor.com");
json payload = check httpClient->get("/data");
```
In case of using var as return type, user can pass the typedesc to the targetType argument.

```ballerina
http:Client httpClient = check new ("https://person.free.beeceptor.com");
var payload = check httpClient->get("/data", targetType = json);
```
When the user expects client data binding to happen, the HTTP error responses (4XX, 5XX) will be categorized as an 
error (http:ClientRequestError, http:RemoteServerError) of the client remote operation. These error types contains
payload, headers and statuscode inside the error detail.

```ballerina
public type Detail record {
    int statusCode;
    map<string[]> headers;
    anydata body;
};
```
The error detail is useful when user wants to dig deeper to understand the backend failure. Here the error message 
is the response phrase.

```ballerina
json|error result = httpClient->post("/backend/5XX", "payload");
if (result is http:RemoteServerError) {
    int statusCode = result.detail().statusCode;
    anydata payload = result.detail().body;
    map<string[]> headers = result.detail().headers;
}
```

## 3. Request routing
Ballerina dispatching logic is implemented to uniquely identify a resource based on the request URI and Method.

### 3.1. URI and HTTP method match

The ballerina dispatcher considers the absolute-resource-path of the service as the base path and the resource 
function name as the path of the resource function for the URI path match.
Ballerina dispatching logic depends on the HTTP method of the request in addition to the URI. Therefore matching only 
the request path will not be sufficient. Once the dispatcher finds a resource, it checks for the method compatibility 
as well. The accessor name of the resource describes the HTTP method where the name of the remote function implicitly 
describes its respective method

### 3.2. Most specific path match
When discovering the resource, the complete path will be considered when figuring out the best match. Perhaps a 
part of the request URI can be matched, yet they won’t be picked unless the longest is matched.

### 3.3. Wild card path match
The resource path can contain a template within the bracket along with the type which represents the wild card. 
i.e `[string… s]`.That is some special way to say that if nothing matched, then the wildcard should be invoked. 
When the best resource match does not exist, a resource with a wild card path can be stated in the API design to 
get requests dispatched without any failure.  

### 3.4. Path parameter template match
PathParam is a parameter which allows you to map variable URI path segments into your resource call. Only the 
resource functions allow this functionality where the resource name can have path templates as a path segment with 
variable type and the identifier within curly braces.
```ballerina
resource function /foo/[string bar]() {
    
}
```
The value of the variable is extracted from the URI and assigned to the resource name parameter during the run-time 
execution.

## 4. Annotations
   
### 4.1. Service configuration
The configurations stated in the http:ServiceConfig  changes the behavior of particular services and applies it to 
all the resources mentioned in the particular services. Some configurations such as Auth, CORS can be overridden by 
resource level configurations. Yet, the service config is useful to cover service level configs.

```ballerina
# ServiceConfig definition
public type HttpServiceConfig record {|
    string host = "b7a.default";
    CompressionConfig compression = {};
    Chunking chunking = CHUNKING_AUTO;
    CorsConfig cors = {};
    ListenerAuthConfig[] auth?;
    string mediaTypeSubtypePrefix?;
    boolean treatNilableAsOptional = true;
    (RequestInterceptor|RequestErrorInterceptor)[]? interceptors = ();
|};

@http:ServiceConfig {
    chunking: http:CHUNKING_ALWAYS
}
service on testListener {
    
}
```

### 4.2. Resource configuration
The resource configuration responsible for shaping the resource function. Most of the behaviours are provided from 
the language itself such as path, HTTP verb as a part of resource function. Some other configs such as CORS, 
compression, auth are defined in the resource config.

```ballerina
# ResourceConfig definition
public type HttpResourceConfig record {|
    string[] consumes = [];
    string[] produces = [];
    CorsConfig cors = {};
    boolean transactionInfectable = true;
    ListenerAuthConfig[]|Scopes auth?;
|};

@http:ResourceConfig {
    produces: ["application/json"]
}
resource function post test() {

}
```

### 4.3. Payload annotation
The payload annotation has two usages. It is used to decorate the resource function payload parameter and to decorate 
the resource return type. 

```ballerina
public type Payload record {|
    string|string[] mediaType?;
|}
```

#### 4.3.1. Payload binding parameter

The request payload binding is supported in resource functions where users can access it through a resource function 
parameter. The @http:Payload annotation is specially introduced to distinguish the request payload with other 
resource function parameters. The annotation can be used to specify values such as mediaType...etc. Users can 
define the potential request payload content type as the mediaType to perform some pre-validations as same as 
Consumes resource config field.

```ballerina
resource function post hello(@http:Payload {mediaType:["application/json", "application/ld+json"]} json payload)  {
    
}
```

During the runtime, the request content-type header is matched against the mediaType field value to validate. If the 
validation fails, the listener returns an error response with the status code of 415 Unsupported Media Type. 
Otherwise the dispatching moves forward. 

#### 4.3.2. Anydata return value info

The same annotation can be used to specify the MIME type return value when a particular resource function returns 
one of the anydata typed values. In this way users can override the default MIME type which the service type has 
defined based on the requirement. Users can define the potential response payload content type as the mediaType 
to perform some pre-runtime validations in addition to the compile time validations as same as produces resource 
config field.

```ballerina
resource function post hello() returns @http:Payload{mediaType:"application/xml"} xml? {
    
}
```

During the runtime, the request accept header is matched against the mediaType field value to validate. If the 
validation fails, the listener returns an error response with the status code of 406 Not Acceptable. Otherwise the 
dispatching moves forward.

The annotation is not mandatory, so if the media type info is not defined, the following table describes the default 
MIME types assigned to each anydata type.

Declared return type | MIME type
---|---
() | (no body)
xml | application/xml
string | text/plain
byte[] | application/octet-stream
map\<json\>, table\<map\<json\>\>, (map\<json\>|table\<map\<json\>\>)[] | application/json
int, float, decimal, boolean | application/json

If anything comes other than above return types will be default to `application/json`.

### 4.4. CallerInfo annotation

The callerInfo annotation associated with the `Caller` is to denote the response type.
It will ensure that the resource function responds with the right type and provides static type information about
the response type that can be used to generate OpenAPI.

```ballerina
resource function post foo(@http:CallerInfo { respondType: http:Accepted } http:Caller hc) returns error?{
    Person p = {};
    hc->respond(Person p);
}
```

### 4.5. Header annotation

```ballerina

resource function post hello(@http:Header {name:"Referer"} string referer) {

}
```
### 4.6. Cache config annotation

This annotation can be used to enable response caching from the resource signature. This allows to set the 
`cache-control`, `etag` and `last-modified` headers in the response.

The default behavior (`@http:CacheConfig`) is to have `must-revalidate,public,max-age=3600` directives in 
`cache-control` header. In addition to that `etag` and `last-modified` headers will be added.

```ballerina
@http:CacheConfig {           // Default Configuration
    mustRevalidate : true,    // Sets the must-revalidate directive
    noCache : false,          // Sets the no-cache directive
    noStore : false,          // Sets the no-store directive 
    noTransform : false,      // Sets the no-transform directive
    isPrivate : false,        // Sets the private and public directive
    proxyRevalidate : false,  // Sets the proxy-revalidate directive
    maxAge : 3600,             // Sets the max-age directive. Default value is 3600 seconds
    sMaxAge : -1,             // Sets the s-maxage directive
    noCacheFields : [],       // Optional fields for no-cache directive
    privateFields : [],       // Optional fields for private directive
    setETag : true,           // Sets the etag header
    setLastModified : true    // Sets the last-modified header
}
```
This annotation can **only** support return types of `anydata` and `SuccessStatusCodeResponse`. (For other return 
values cache configuration will not be added through this annotation)

```ballerina
// Sets the cache-control header as "public,must-revalidate,max-age=5". Also sets the etag header.
// last-modified header will not be set
resource function get cachingBackEnd(http:Request req) returns @http:CacheConfig{maxAge : 5, 
    setLastModified : false} string {

    return "Hello, World!!"
}
```

## 5. URL parameters
### 5.1. Path
Path params are specified in the resource name itself. Path params can be specified in the types of string, int, 
boolean, decimal and float. During the request runtime the respective path segment is matched and casted into param 
type. Users can access it within the resource function, and it is very useful when designing APIs with dynamically 
changing path segments.

### 5.2. Query
Query params can be accessed via the resource signature without an annotation or accessed via request functions.

```ballerina
# Gets the query parameters of the request as a map consisting of a string array.
public isolated function getQueryParams() returns map<string[]> {
    
}

# Gets the query param value associated with the given key.
public isolated function getQueryParamValue(string key) returns string? {

}

# Gets all the query param values associated with the given key.
public isolated function getQueryParamValues(string key) returns string[]? {

}
```
### 5.3. Matrix
The matrix params are one of the URL param which is supported access in ballerina using a function which bound to 
the request

```ballerina
# Gets the matrix parameters of the request.
public isolated function getMatrixParams(string path) returns map<any> {
    
}
```

## 6. Request and Response
The request and the response represent the message/data which travel over the network using HTTP. The request object 
models the inbound/outbound message with request oriented properties, headers and payload. Followings are the properties 
associated with the `http:Request` which get populated for each request during the runtime.

```ballerina
public class Request {
   public string rawPath = "";
   public string method = "";
   public string httpVersion = "";
   public string userAgent = "";
   public string extraPathInfo = "";
   public RequestCacheControl? cacheControl = ();
   public MutualSslHandshake? mutualSslHandshake = ();
}
```

The header and the payload manipulation can be done using the functions associated to the request.

Same as request, the response object also models the inbound/outbound message with the response oriented properties 
and headers. Followings are the properties associated with the `http:Response` which get populated for each response 
during the runtime.

```ballerina
public class Response {
    public int statusCode = 200;
    public string reasonPhrase = "";
    public string server = "";
    public string resolvedRequestedURI = "";
    public ResponseCacheControl? cacheControl = ();
}
```

The header and the payload manipulation can be done using the functions associated to the response.

## 7. Header and Payload
The header and payload are the main components of the request and response. In the world of MIME, that is called 
Entity header and Entity body. Ballerina supports multiple payload types and allows convenient functions to access 
headers along with other properties.

### 7.1. Parse header functions

```ballerina
# Parses the header value which contains multiple values or parameters.
parseHeader(string headerValue) returns HeaderValue[]|ClientError  {

}
```

## 8. Interceptor and Error handling
### 8.1 Interceptor
Interceptor enhances the HTTP package with interceptors. Interceptors typically do small units of work such as logging, header 
manipulation, state publishing, etc, before resources are invoked. The ability to execute some common logic for all 
the inbound requests and outbound responses has proven to be highly useful. It typically includes some small unit of 
work such as the below.
 - Logging
 - Header manipulation
 - Observability
 - Throttling
 - Validating
 - Securing

Interceptors are designed for both request and response flows. Currently, only the Request interceptor has implemented.

#### 8.1.1 Request interceptor
Following is an example of RequestInterceptor written in Ballerina swan-lake. RequestInterceptor can only have one 
resource function.

```ballerina
service class RequestInterceptor {
   *http:RequestInterceptor;
 
   resource function 'default [string… path](http:RequestContext ctx, http:Caller caller,
                       http:Request req) returns error? {
       request.setHeader("X-requestHeader", "RequestInterceptor");
       ctx.next();
   }
}
```

Since interceptors work with network activities, it must be either a remote or resource function. In this case resource 
functions are used for RequestInterceptor as it gives more flexibility. With resource functions interceptors can be engaged 
based on HTTP method and path.

For instance consider a scenario where there are two resources; one on path foo whereas the other on path bar. If the 
user writes a interceptor as follows, it would only get hit when the request is directed to foo resource.

```ballerina
service class RequestInterceptor {
   *http:RequestInterceptor;
 
   resource function 'default foo(http:RequestContext ctx, http:Caller caller,
                       http:Request req) returns error? {
       request.setHeader("X-requestHeader", "RequestInterceptor");
       ctx.next();
   }
}
```

##### 8.1.1.1 RequestContext  
Following is the rough definition of the interceptor context.
```ballerina
public isolated class RequestContext {
    private final map<value:Cloneable|isolated object {}> attributes = {};

    public isolated function add(string 'key, value:Cloneable|isolated object {} value) {
        if value is value:Cloneable {
            lock {
                self.attributes['key] = value.clone();
            }
        }
        else {
            lock {
                self.attributes['key] = value;
            }   
        }
    }

    public isolated function get(string 'key) returns value:Cloneable|isolated object {} {
        lock {
            return self.attributes.get('key);
        }
    }

    public isolated function remove(string 'key) {
        lock {
            value:Cloneable|isolated object {} _ = self.attributes.remove('key);
        }
    }

    public isolated function next() returns NextService|error? = external;
}
```

##### 8.1.1.2 next() Method  
However, there is an addition when it comes to RequestContext. A new method namely, next() is introduced to control 
the execution flow. Users must invoke next() method in order to trigger the next interceptor in the pipeline. 
Previously, this was controlled by returning a boolean value which is quite cryptic and confusing.

Moreover, invoking next() method results in immediately executing the next interceptor in the pipeline. Which means 
whatever below the next() method will only get executed after the completion of execution of the next Interceptor.

If the users forget to call next() and don't respond either, the request will be left hanging.

##### 8.1.1.3 Returning error?
Resource functions can return NextService|error?. They can return only error? when using the Caller.
Also, in case of an error, interceptor pipeline execution jumps to the nearest RequestErrorInterceptor in the 
pipeline. This RequestErrorInterceptor is not necessarily the last interceptor in the pipeline, it can be anywhere 
in the chain.

#### 8.1.2 Request error interceptor
As mentioned above this is a special kind of interceptor designed to handle errors. These interceptors can  
be placed anywhere in the request or response interceptor chain. The framework automatically adds default 
RequestErrorInterceptor and ResponseErrorInterceptor which basically prints the error 
message to the console.

Users can override these interceptors by defining their own ones as follows. Users don’t have to specifically engage 
these interceptors as they only have fixed positions and they are always executed. The only additional argument in this 
case is error err.

```ballerina
service class RequestErrorInterceptor {
   *http:RequestErrorInterceptor;
 
   remote function 'default [string… path](http:RequestContext ctx, http:Caller caller,
                       http:Request req, error err) returns error? {
       // deal with the error
   }
}
```

#### 8.1.3 Engaging Interceptors
##### 8.1.3.1 Service Level
Interceptors could get engaged at service level. One reason for this is that users may want to engage two different 
interceptor chains for each service even though it is attached to the same Listener. At the service level resource 
function paths are relative to the service base path.
```ballerina
@http:ServiceConfig{
   interceptors: [requestInterceptor, responseInterceptor]
}
```

##### 8.1.3.2 Listener Level
Interceptors could get engaged at Listener level as well. At the listener level resource function paths are 
relative to the /.
```ballerina
listener http:Listener echoListener = new http:Listener(9090, config = {interceptors: [requestInterceptor, responseInterceptor]});
```

##### 8.1.3.3 Execution Order of Interceptors

![img.png](resources/img.png)
In the above example blue dashed box represents the RequestErrorInterceptor and blue boxes simply represent the 
RequestInterceptors whereas green dashed box represents the ResponseErrorInterceptor(TBA) and green boxes simply represent the 
ResponseInterceptors. The new execution orders is as follows,
```
RequestInterceptor/RequestErrorInterceptor: 1, 2, 4, 5
ResponseInterceptor/ResponseErrorInterceptor: 5, 3, 0
```

The execution order when interceptors are engaged at both service and listener levels is as follows;

```
ListenerLevel : RequestInterceptors -> ServiceLevel : RequestInterceptors -> TargetService -> 
ServiceLevel : ResponseInterceptors -> ListenerLevel : ResponseInterceptors
```

#### 8.1.4 Data Binding
Both requestInterceptor and responseInterceptor methods support data binding. Which means users can directly access the 
payload, headers and query parameters. In order to get hold of the headers and the payload, users must use 
@http:Payload and @http:Headers.


#### 8.1.5 Return to Respond
There is a key difference between interceptors and Resources. HTTP resources allow returning values which in turn 
results in HTTP responses. But interceptors do not support this behavior. Because unlike resources interceptors do not 
sit at the edge. Therefore, it results in complications when implementing the next() method.

### 8.2 Error handling
### 8.2.1 Trace log
The HTTP trace logs can be used to monitor the HTTP traffic that goes in and out of Ballerina.
The HTTP trace logs are **disabled as default**.
To enable trace logs, the log level has to be set to TRACE using the runtime argument:
`-Cballerina.http.traceLogConsole=true.`

The HTTP access logs and trace logs are **disabled as default**. To enable, the configurations can be set by the 
following `config.toml` file:

The configurations can be set in the `config.toml` file for advanced use cases such as specifying the file path to 
save the trace logs and specifying the hostname and port of a socket service to publish the trace logs.

```toml
[ballerina.http.traceLogAdvancedConfig]
# Enable printing trace logs in console
console = true              # Default is false
# Specify the file path to save the trace logs  
path = "testTraceLog.txt"   # Optional
# Specify the hostname and port of a socket service to publish the trace logs
host = "localhost"          # Optional
port = 8080                 # Optional
```
### 8.2.2 Access log

Ballerina supports HTTP access logs for HTTP services. The access log format used is the combined log format.
The HTTP access logs are **disabled as default**.
To enable access logs, set console=true under the ballerina.http.accessLogConfig in the Config.toml file. Also, 
the path field can be used to specify the file path to save the access logs.

```toml
[ballerina.http.accessLogConfig]
# Enable printing access logs in console
console = true              # Default is false
# Specify the file path to save the access logs  
path = "testAccessLog.txt"  # Optional
```

## 9. Security

### 9.1 Authentication and Authorization

There are two ways to enable authentication and authorization in HTTP.

1. Declarative approach
2. Imperative approach

#### 9.1.1 Declarative Approach

This is also known as the configuration-driven approach, which is used for simple use cases, where users have to 
provide a set of configurations and do not need to be worried more about how authentication and authorization works. 
The user does not have full control over the configuration-driven approach.

The service configurations are used to define the authentication and authorization configurations. Users can 
configure the configurations needed for different authentication schemes and configurations needed for 
authorizations of each authentication scheme. Also, the configurations can be provided at the service level. 
The priority will be given from bottom to top. Then, the auth handler creation and request 
authentication/authorization is handled internally without user intervention. The requests that succeeded both 
authentication and/or authorization phases according to the configurations will be passed to the business logic layer.

##### 9.1.1.1 Listener - File User Store

```ballerina
@http:ServiceConfig {
    auth: [
        {
            fileUserStoreConfig: {},
            scopes: ["admin"]
        }
    ]
}
service /foo on new http:Listener(9090) {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
```
```ballerina
# Config.toml

[[ballerina.auth.users]]
username="alice"
password="alice@123"
scopes=["developer"]

[[ballerina.auth.users]]
username="ldclakmal"
password="ldclakmal@123"
scopes=["developer", "admin"]

[[ballerina.auth.users]]
username="eve"
password="eve@123"
```

##### 9.1.1.2. Listener - LDAP User Store

```ballerina
@http:ServiceConfig {
    auth: [
        {
            ldapUserStoreConfig: {
                domainName: "avix.lk",
                connectionUrl: "ldap://localhost:389",
                connectionName: "cn=admin,dc=avix,dc=lk",
                connectionPassword: "avix123",
                userSearchBase: "ou=Users,dc=avix,dc=lk",
                userEntryObjectClass: "inetOrgPerson",
                userNameAttribute: "uid",
                userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
                userNameListFilter: "(objectClass=inetOrgPerson)",
                groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
                groupEntryObjectClass: "groupOfNames",
                groupNameAttribute: "cn",
                groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
                groupNameListFilter: "(objectClass=groupOfNames)",
                membershipAttribute: "member",
                userRolesCacheEnabled: true,
                connectionPoolingEnabled: false,
                connectionTimeout: 5,
                readTimeout: 60
            },
            scopes: ["admin"]
        }
    ]
}
service /foo on new http:Listener(9090) {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
```

##### 9.1.1.3 Listener - JWT

```ballerina
@http:ServiceConfig {
    auth: [
        {
            jwtValidatorConfig: {
                issuer: "wso2",
                audience: "ballerina",
                signatureConfig: {
                    certFile: "/path/to/public.crt"
                },
                scopeKey: "scp"
            },
            scopes: ["admin"]
        }
    ]
}
service /foo on new http:Listener(9090) {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
```

##### 9.1.1.4 Listener - OAuth2
```ballerina
@http:ServiceConfig {
    auth: [
        {
            oauth2IntrospectionConfig: {
                url: "https://localhost:9445/oauth2/introspect",
                tokenTypeHint: "access_token",
                scopeKey: "scp",
                clientConfig: {
                    customHeaders: {"Authorization": "Basic YWRtaW46YWRtaW4="},
                    secureSocket: {
                        cert: "/path/to/public.crt"
                    }
                }
            },
            scopes: ["admin"]
        }
    ]
}
service /foo on new http:Listener(9090) {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
```

##### 9.1.1.5 Client - Basic Auth
```ballerina
http:Client c = check new ("https://localhost:9090",
    auth = {
        username: "tom",
        password: "123"
    }
);

public function main() returns error? {
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.1.6 Client - Bearer Token Auth
```ballerina
http:Client c = check new ("https://localhost:9090",
    auth = {
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiw" +
               "ibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2Q" +
               "T4fwpMeJf36POk6yJV_adQssw5c"
    }
);

public function main() returns error? {
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.1.7 Client - Self-Signed JWT
```ballerina
http:Client c = check new ("https://localhost:9090",
    auth = {
        username: "ballerina",
        issuer: "wso2",
        audience: ["ballerina", "ballerina.org", "ballerina.io"],
        keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
        jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
        customClaims: {"scp": "admin"},
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: "/path/to/private.key"
            }
        }
    }
);

public function main() returns error? {
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.1.8 Client - Bearer Token OAuth2
```ballerina
http:Client c = check new ("https://localhost:9090",
    auth = {
        token: "56ede317-4511-44b4-8579-a08f094ee8c5"
    }
);

public function main() returns error? {
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.1.9 Client - Grant Types OAuth2
```ballerina
http:OAuth2ClientCredentialsGrantConfig config = {
    tokenUrl: "https://localhost:8080/oauth2/token/authorize",
    clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxS",
    clientSecret: "9205371918321623741"
};

http:Client c = check new ("https://localhost:9090", auth = config);

public function main() returns error? {
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

#### 9.1.2 Imperative Approach
This is also known as the code-driven approach, which is used for advanced use cases, where users need to be 
worried more about how authentication and authorization work and need to have further customizations. The user has 
full control of the code-driven approach. The handler creation and authentication/authorization calls are made by 
the user at the business logic layer.

##### 9.1.2.1 Listener - File User Store

```ballerina
http:FileUserStoreConfig config = {};
http:ListenerFileUserStoreBasicAuthHandler handler = new (config);

service /foo on new http:Listener(9090) {
    resource function post bar(@http:Header string Authorization) returns string|http:Unauthorized|http:Forbidden {
        auth:UserDetails|http:Unauthorized authn = handler.authenticate(Authorization);
        if (authn is http:Unauthorized) {
            return authn;
        }
        http:Forbidden? authz = handler.authorize(<auth:UserDetails>authn, "admin");
        if (authz is http:Forbidden) {
            return authz;
        }
        // business logic
    }
}
```
```ballerina
# Config.toml
[ballerina.observe]
enabled=true
provider="noop"

[[auth.users]]
username="admin"
password="123"
scopes=["write", "update"]
```

##### 9.1.2.2 Listener - LDAP User Store

```ballerina
http:LdapUserStoreConfig config = {
    domainName: "avix.lk",
    connectionUrl: "ldap://localhost:389",
    connectionName: "cn=admin,dc=avix,dc=lk",
    connectionPassword: "avix123",
    userSearchBase: "ou=Users,dc=avix,dc=lk",
    userEntryObjectClass: "inetOrgPerson",
    userNameAttribute: "uid",
    userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
    userNameListFilter: "(objectClass=inetOrgPerson)",
    groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
    groupEntryObjectClass: "groupOfNames",
    groupNameAttribute: "cn",
    groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
    groupNameListFilter: "(objectClass=groupOfNames)",
    membershipAttribute: "member",
    userRolesCacheEnabled: true,
    connectionPoolingEnabled: false,
    connectionTimeout: 5,
    readTimeout: 60
};
http:ListenerLdapUserStoreBasicAuthHandler handler = new (config);

service /foo on new http:Listener(9090) {
    resource function post bar(@http:Header string Authorization) returns string|http:Unauthorized|http:Forbidden {
        auth:UserDetails|http:Unauthorized authn = handler->authenticate(Authorization);
        if (authn is http:Unauthorized) {
            return authn;
        }
        http:Forbidden? authz = handler->authorize(<auth:UserDetails>authn, "admin");
        if (authz is http:Forbidden) {
            return authz;
        }
        // business logic
    }
}
```

##### 9.1.2.3 Listener - JWT

```ballerina
http:JwtValidatorConfig config = {
    issuer: "ballerina",
    audience: ["wso2"],
    signatureConfig: {
        jwksConfig: {
            url: "https://localhost:8080/jwks"
        }
    }
};
http:ListenerJwtAuthHandler handler = new (config);

service /foo on new http:Listener(9090) {
    resource function post bar(@http:Header string Authorization) returns string|http:Unauthorized|http:Forbidden {
        jwt:Payload|http:Unauthorized authn = handler.authenticate(Authorization);
        if (authn is http:Unauthorized) {
            return authn;
        }
        http:Forbidden? authz = handler.authorize(<jwt:Payload>authn, "admin");
        if (authz is http:Forbidden) {
            return authz;
        }
        // business logic
    }
}
```

##### 9.1.2.4 Listener - OAuth2

```ballerina
http:OAuth2IntrospectionConfig config = {
    url: "https://localhost:8080/oauth2/introspect",
    tokenTypeHint: "access_token"
};
http:ListenerOAuth2Handler handler = new (config);

service /foo on new http:Listener(9090) {
    resource function post bar(@http:Header string authorization) returns string|http:Unauthorized|http:Forbidden {
        oauth2:IntrospectionResponse|http:Unauthorized|http:Forbidden auth = handler->authorize(authorization, "admin");
        if (auth is http:Unauthorized || auth is http:Forbidden) {
            return auth;
        }
        // business logic
    }
}
```

##### 9.1.2.5 Client - Basic Auth
```ballerina
http:CredentialsConfig config = {
    username: "tom",
    password: "123"
};
http:ClientBasicAuthHandler handler = new (config);

http:Client c = check new ("https://localhost:9090");

public function main() returns error? {
    http:Request req = new;
    req = check handler.enrich(req);
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.2.6 Client - Bearer Token Auth
```ballerina
http:BearerTokenConfig config = {
    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFt" +
           "ZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf3" +
           "6POk6yJV_adQssw5c"
};
http:ClientBearerTokenAuthHandler handler = new (config);

http:Client c = check new ("https://localhost:9090");

public function main() returns error? {
    http:Request req = new;
    req = check handler.enrich(req);
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.2.7. Self-Signed JWT
```ballerina
http:JwtIssuerConfig config = {
    username: "admin",
    issuer: "ballerina",
    audience: ["wso2"],
    signatureConfig: {
        config: {
            keyFile: "/path/to/private.key",
            keyPassword: "password"
        }
    }
};
http:ClientSelfSignedJwtAuthHandler handler = new (config);

http:Client c = check new ("https://localhost:9090");

public function main() returns error? {
    http:Request req = new;
    req = check handler.enrich(req);
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.2.8. Client - Bearer Token OAuth2
```ballerina
http:BearerTokenConfig config = {
    token: "JhbGciOiJIIiwiaWF0IjUzI1NiIsInR5cCI6IkpXVCJ9WIiOiIxMjM0NTY3ODkwI"
};
http:ClientBearerTokenAuthHandler handler = new (config);

http:Client c = check new ("https://localhost:9090");

public function main() returns error? {
    http:Request req = new;
    req = check handler.enrich(req);
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

##### 9.1.2.9. Client - Grant Types OAuth2
```ballerina
http:OAuth2ClientCredentialsGrantConfig config = {
    tokenUrl: "https://localhost:8080/oauth2/token/authorize",
    clientId: "3MVG9YDQS5WtC11paU2WcQjBB3L5w4gz52uriT8ksZ3nUVjKvrfQMrU4uvZohTftxS",
    clientSecret: "9205371918321623741"
};
http:ClientOAuth2Handler handler = new (config);

http:Client c = check new ("https://localhost:9090");

public function main() returns error? {
    http:Request req = new;
    req = check handler->enrich(req);
    json response = check c->get("/foo/bar");
    // evaluate response
}
```

### 9.2 SSL/TLS and Mutual SSL

The HTTPS listener could connect to or interact with an HTTPS client. The `http:ListenerSecureSocket` configuration
of the listener exposes the HTTPS connection related configs.

#### 9.2.1 Listener - SSL/TLS
```ballerina
listener http:Listener securedEP = new(9090,
    secureSocket = {
        key: {
            certFile: "/path/to/public.crt",
            keyFile: "/path/to/private.key"
        }
    }
);

service /foo on securedEP {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
```

#### 9.2.2 Listener - Mutual SSL

The mutual SSL support which is a certificate-based authentication process in which two parties 
(the client and server) authenticate each other by verifying the digital certificates. It ensures that both 
parties are assured of each other’s identity.

```ballerina
listener http:Listener securedEP = new(9090,
    secureSocket = {
        key: {
            certFile: "/path/to/public.crt",
            keyFile: "/path/to/private.key"
        },

        mutualSsl: {
            verifyClient: http:REQUIRE,
            cert: "/path/to/public.crt"
        },

        protocol: {
            name: http:TLS,
            versions: ["TLSv1.2", "TLSv1.1"]
        },

        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]

    }
);
service /foo on securedEP {
    resource function get bar() returns string {
        return "Hello, World!";
    }
}
```

#### 9.2.3 Client - SSL/TLS

```ballerina
http:Client securedEP = check new("https://localhost:9090",
    secureSocket = {
        cert: "/path/to/public.crt"
    }
);

public function main() returns error? {
    string response = check securedEP->get("/foo/bar");
    io:println(response);
}
```

#### 9.2.4 Client - Mutual SSL

```ballerina
http:Client securedEP = check new("https://localhost:9090",
    secureSocket = {
        key: {
            certFile: "/path/to/public.crt",
            keyFile: "/path/to/private.key"
        },
        cert: "/path/to/public.crt",
        protocol: {
            name: http:TLS
        },
        ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]

    }
);
public function main() returns error? {
    string response = check securedEP->get("/foo/bar");
    io:println(response);
}
```

## 10. Protocol upgrade
### 10.1. HTTP/2
The version 2 of HTTP protocol is supported in both Listener and Client space which could be configured through the 
respective configuration.

```ballerina
// Listener declaration
listener http:Listener http2ServiceEP = new (7090, config = {httpVersion: "2.0"});

// Client declaration
http:Client clientEP = check new ("http://localhost:7090", {httpVersion: "2.0"});
```


There are few API level additions when it comes to the HTTP/2 design such as Push promise and promise response.
#### 10.1.1. Push Promise and Promise Response
Push Promise and Promise response are the only application level new semantics which are introduced by HTTP2.

Other protocol changes such as streams, messages, frames, request prioritization, flow control, header compression, 
etc. are all lower level changes that can be handled by the HTTP listener seamlessly from the user.
