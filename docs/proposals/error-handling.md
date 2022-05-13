# Proposal: Error Handling

_Owners_: @shafreenAnfar @chamil321 @ayeshLK @TharmiganK  
_Reviewers_: @sameerajayasoma @chamil321    
_Created_: 2022/05/13  
_Updated_: 2022/05/13  
_Issue_: [#2669](https://github.com/ballerina-platform/ballerina-standard-library/issues/2669)

## Summary
Error handling is an integral part of any network program. Errors can be returned by many components such as interceptors, dispatcher, data-binder, security handlers, etc. This proposal is to discuss how to capture those errors and deal with them.

## Goals
- Allow users to catch errors and deal with it

## Motivation

As mentioned in the summary section. In any network program, there can be errors returned by different components. These errors are often handled by a default handler and sent back as `500 Internal Server Error` with an entity-body. However, this often causes problems because when designing any API consistency matters. Therefore, all the responses must have a consistent format.

As a result, almost all the real API requires overriding the default error handler and replacing it with their own error handlers. At the moment HTTP library doesn't have a solid way of doing this.

## Description

Error handlers were briefly discussed in [#692](https://github.com/ballerina-platform/ballerina-standard-library/issues/692). Error handlers can be placed in the interceptor pipeline. These 
error handlers can catch any errors returned by the main service, interceptors, dispatcher, data-binder, security handlers, etc.  Whenever one of these components returns an error the execution jumps to the closest error handler in the interceptor pipeline.

For instance, say the data-binder returned an error. In this case, because data binding happens just before dispatching to the service resource, the first error handler at the service level catches the error. If there is no error handler at the service level, the first error handler at the listener level catches the error.

There are two types of error handlers.
1. `RequestErrorInterceptor`
2. `ResponseErrorInterceptor`

### RequestErrorInterceptor
As the name says this type of error interceptor is only engaged in the request path. Following is how you can define one.

```ballerina
# The HTTP request error interceptor service object  
public type RequestErrorInterceptor distinct service object {};

service class RequestErrorInterceptor {
   *http:RequestErrorInterceptor;
 
   resouce function 'default [string… path](http:RequestContext ctx, http:Caller caller,
                       http:Request req, error err) returns http:RequestInterceptor|error? {
       // deal with the error
       return ctx.next();
   }
}
```
The only mandatory argument is `error` the rest are optional. Just like in the main service, it is possible to return values to send back HTTP responses. This terminates the request path and results in triggering the response path of the interceptor pipeline. Following is such an example.

```ballerina
service class RequestErrorInterceptor {
   *http:RequestErrorInterceptor;
 
   resouce function 'default [string… path](error err) returns http:NotFound  {
       http:NotFound nf = { body: { msg: err.message() } };
       return nf;
   }
}
```

### ResponseErrorInterceptor
As the name says this type of error interceptor is only engaged in the response path. Following is how you can define one.
```ballerina
# The HTTP response error interceptor service object  
public type ResponseErrorInterceptor distinct service object {};

service class ResponseErrorInterceptor {
   *http:ResponseErrorInterceptor;
 
   remote function interceptResponseError(http:RequestContext ctx,
                       http:Response res, error err) returns http:ResponseInterceptor|error? {
       // deal with the error
       return ctx.next();
   }
}
```
The only mandatory argument is `error` the rest are optional. Just like in the main service, it is possible to return values to send back HTTP responses. This overrides the current response and results in triggering the next immediate response interceptor. Following is such an example.

```ballerina
service class ResponseErrorInterceptor {
   *http:ResponseErrorInterceptor;
 
   remote function interceptResponseError(error err) returns http:NotFound {
       http:NotFound nf = { body: { msg: err.message()} };
       return nf;
   }
}
```
It is possible to get hold of the original response using the argument `http:Response res` and then alter the response headers and the body. However, in that case, the OpenAPI tool will not be able to capture those changes.

> **Note**: The best way to catch all the errors is by having a `ResponseErrorInterceptor` at the `Listener` level.

### DefaultErrorInterceptor
`DefaultErrorInterceptor` is a `ResponseErrorInterceptor` which will be added by the Listener as the 
first interceptor in the interceptor pipeline. Hence, any error which is not handled by other error interceptors 
will be handled by this error interceptor. Following is how the internal default error interceptor is defined

```ballerina
service class DefaultErrorInterceptor {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError(error err) returns http:Response {
        http:Response res = new;
        res.setTextPayload(err.message());
        // By default, the error response is set to 500 - Internal Server Error
        // However, if the error is an internal error which has a different error
        // status code (4XX or 5XX) then this 500 status code will be overwritten 
        // by the original status code.
        res.statusCode = 500;
        return res;
    }
}
```
