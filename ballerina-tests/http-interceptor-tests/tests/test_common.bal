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
import ballerina/lang.'string as strings;

public type Person record {|
    string name;
    int age;
|};

service class DefaultRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("default-request-interceptor", "true");
       ctx.set("last-interceptor", "default-request-interceptor");
       return ctx.next();
    }
}

service class DataBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload string payload, @http:Header {name: "interceptor"} string header) returns http:NextService|error? {
       ctx.set("request-payload", payload);
       ctx.set("last-interceptor", header);
       return ctx.next();
    }
}

service class StringPayloadBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload string payload) returns http:NextService|error? {
       ctx.set("request-payload", payload);
       return ctx.next();
    }
}

service class RecordPayloadBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload Person person) returns http:NextService|error? {
       ctx.set("request-payload", person);
       return ctx.next();
    }
}

service class RecordArrayPayloadBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload Person[] persons) returns http:NextService|error? {
       ctx.set("request-payload", persons.toJsonString());
       return ctx.next();
    }
}

service class ByteArrayPayloadBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload byte[] person) returns http:NextService|error? {
       ctx.set("request-payload", strings:fromBytes(person));
       return ctx.next();
    }
}

service class RequestInterceptorConsumePayload {
    *http:RequestInterceptor;

    resource function post [string path](http:RequestContext ctx, http:Request req, boolean consumePayloadInInterceptor)
            returns http:NextService|error? {
        if consumePayloadInInterceptor {
            json _ = check req.getJsonPayload();
        }
        return ctx.next();
    }
}

service class RequestInterceptorSetPayload {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("request-interceptor-setpayload", "true");
       req.setTextPayload("Text payload from request interceptor");
       ctx.set("last-interceptor", "request-interceptor-setpayload");
       return ctx.next();
    }
}

service class RequestInterceptorCallerRespond {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Caller caller) returns error? {
        http:Response res = new();
        res.setHeader("request-interceptor-caller-respond", "true");
        res.setTextPayload("Response from caller inside interceptor");
        check caller->respond(res);
    }
}

service class RequestInterceptorCallerRespondError {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Caller caller) returns error? {
        ctx.set("last-interceptor", "request-interceptor-caller-respond-error");
        check caller->respond(error("Request interceptor returns an error"));
    }
}

service class RequestInterceptorCallerRespondContinue {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Caller caller) returns http:NextService|error? {
        http:Response res = new();
        res.setHeader("last-interceptor", "request-interceptor-caller-respond");
        res.setTextPayload("Response from caller inside interceptor");
        check caller->respond(res);
        return ctx.next();
    }
}

service class RequestInterceptorReturnsError {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns error {
       req.setHeader("request-interceptor-error", "true");
       ctx.set("last-interceptor", "request-interceptor-error");
       return error("Request interceptor returns an error");
    }
}

service class LastRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       string|error val = ctx.get("last-interceptor").ensureType(string);
       string header = val is string ? val : "last-request-interceptor";
       req.setHeader("last-request-interceptor", "true");
       req.setHeader("last-interceptor", header);
       return ctx.next();
    }
}

service class RequestInterceptorReturnsResponse {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload string payload) returns http:Response {
       http:Response res = new;
       string|error val = ctx.get("last-interceptor").ensureType(string);
       string header = val is string ? val : "request-interceptor-returns-response";
       res.setHeader("request-interceptor-returns-response", "true");
       res.setHeader("last-interceptor", header);
       res.setTextPayload("Response from Interceptor : " + payload);
       return res;
    }
}

service class RequestInterceptorReturnsStatusCodeResponse {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Request req) returns http:NotFound|http:Ok {
       boolean isHeaderPresent = req.getHeader("header") is string ? true : false;
       if isHeaderPresent {
           http:Ok ok = {
               body: "Response from Request Interceptor",
               headers: {
                   "last-interceptor" : "request-interceptor-returns-status"
               }
           };
           return ok;
       } else {
           http:NotFound nf = {
               body: "Header not found in request"
           };
           return nf;
       }
    }
}

service class RequestInterceptorCheckHeader {
    *http:RequestInterceptor;
    final string headerName;

    function init(string headerName) {
        self.headerName = headerName;
    }

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:Response|http:NextService|error? {
       req.setHeader("request-interceptor-check-header", "true");
       ctx.set("last-interceptor", "request-interceptor-check-header");
       boolean isHeaderPresent = req.getHeader(self.headerName) is string ? true : false;
       if isHeaderPresent {
           return ctx.next();
       } else {
           http:Response res = new;
           foreach string reqHeader in req.getHeaderNames() {
               res.setHeader(reqHeader, check req.getHeader(reqHeader));
           }
           res.statusCode = 404;
           res.setTextPayload("Header : " + self.headerName + " not found");
           return res;
       }
    }
}

service class DefaultRequestErrorInterceptor {
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](error err, http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("default-request-error-interceptor", "true");
       req.setTextPayload(err.message());
       ctx.set("last-interceptor", "default-request-error-interceptor");
       return ctx.next();
    }
}

service class RequestErrorInterceptorReturnsErrorMsg {
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](error err) returns string {
       return err.message();
    }
}

service class RequestErrorInterceptorReturnsError {
    *http:RequestErrorInterceptor;

    resource function 'default [string... path](error err, http:RequestContext ctx, http:Request req) returns error {
       req.setHeader("request-error-interceptor-error", "true");
       ctx.set("last-interceptor", "request-error-interceptor-error");
       return error("Request error interceptor returns an error");
    }
}

service class RequestInterceptorWithoutCtxNext {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) {
       req.setHeader("request-interceptor-without-ctx-next", "true");
       ctx.set("last-interceptor", "request-interceptor-without-ctx-next");
    }
}

service class GetRequestInterceptor {
    *http:RequestInterceptor;

    resource function get [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("get-interceptor", "true");
       ctx.set("last-interceptor", "get-interceptor");
       return ctx.next();
    }
}

service class GetFooRequestInterceptor {
    *http:RequestInterceptor;

    resource function get [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("get-foo-interceptor", "true");
       ctx.set("last-interceptor", "get-foo-interceptor");
       return ctx.next();
    }
}

service class PostRequestInterceptor {
    *http:RequestInterceptor;

    resource function post [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("post-interceptor", "true");
       ctx.set("last-interceptor", "post-interceptor");
       return ctx.next();
    }
}

service class DefaultRequestInterceptorBasePath {
    *http:RequestInterceptor;

    resource function 'default foo(http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("default-base-path-interceptor", "true");
       ctx.set("last-interceptor", "default-base-path-interceptor");
       return ctx.next();
    }
}

service class GetRequestInterceptorBasePath {
    *http:RequestInterceptor;

    resource function get bar(http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("default-base-path-interceptor", "true");
       ctx.set("last-interceptor", "get-base-path-interceptor");
       return ctx.next();
    }
}

service class RequestInterceptorSkip {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("skip-interceptor", "true");
       ctx.set("last-interceptor", "skip-interceptor");
       http:NextService|error? nextService = ctx.next();
       if (nextService is error) {
           return nextService;
       }
       return ctx.next();
    }
}

service class RequestInterceptorCtxNext {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns error? {
       req.setHeader("request-interceptor-ctx-next", "true");
       ctx.set("last-interceptor", "request-interceptor-ctx-next");
       http:NextService|error? nextService = ctx.next();
       if (nextService is error) {
           return nextService;
       }
    }
}

service class RequestInterceptorWithQueryParam {
    *http:RequestInterceptor;

    resource function 'default [string... path](string q1, int q2, http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("request-interceptor-query-param", "true");
       req.setHeader("q1", q1);
       req.setHeader("q2", q2.toString());
       ctx.set("last-interceptor", "request-interceptor-query-param");
       return ctx.next();
    }
}

service class RequestInterceptorWithVariable {
    *http:RequestInterceptor;
    final string name;

    function init(string name) {
        self.name = name;
    }

    function getName() returns string {
        return self.name;
    }

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader(self.getName(), "true");
       ctx.set("last-interceptor", self.getName());
       return ctx.next();
    }
}

service class RequestInterceptorUserAgentField {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
        req.setHeader("req-interceptor-user-agent", req.userAgent);
        ctx.set("last-interceptor", "user-agent-interceptor");
        return ctx.next();
    }
}

service class RequestInterceptorNegative1 {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Request req) returns http:NextService|error? {
       req.setHeader("request-interceptor-negative1", "true");
       http:RequestContext ctx = new();
       ctx.set("last-interceptor", "request-interceptor-negative1");
       return ctx.next();
    }
}

service class RequestInterceptorNegative2 {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Request req) returns http:RequestInterceptor {
       req.setHeader("request-interceptor-negative2", "true");
       return new DefaultRequestInterceptor();
    }
}

service class RequestInterceptorNegative3 {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Request req, http:RequestContext ctx) returns http:NextService|error? {
       req.setHeader("request-interceptor-negative3", "true");
       http:NextService|error? nextService = ctx.next();
       if nextService is error {
          return nextService;
       }
       return new DefaultRequestInterceptor();
    }
}

string largePayload = "WSO2 was founded by Sanjiva Weerawarana, Paul Fremantle and Davanum Srinivas in August 2005, " +
    "backed by Intel Capital, Toba Capital, and Pacific Controls. Weerawarana[3] was an IBM researcher and a founder " +
    "of the Web services platform.[4][5] He led the creation of IBM SOAP4J,[6] which later became Apache SOAP, and was" +
    " the architect of other notable projects. Fremantle was one of the authors of IBM's Web Services Invocation Framework" +
    " and the Web Services Gateway.[7] An Apache member since the original Apache SOAP project, Freemantle oversaw the " +
    "donation of WSIF and WSDL4J to Apache and led IBM's involvement in the Axis C/C++ project. Fremantle became WSO2's chief" +
    " technology officer (CTO) in 2008,[8] and was named one of Infoworld's Top 25 CTOs that year.[9] In 2017, Tyler Jewell " +
    "took over as CEO.[10] In 2019, Vinny Smith became the Executive Chairman.[11] WSO2's first product was code-named Tungsten," +
    " and was meant for the development of web applications. Tungsten was followed by WSO2 Titanium, which later became WSO2 " +
    "Enterprise Service Bus (ESB).[12] In 2006, Intel Capital invested $4 million in WSO2,[13] and continued to invest in " +
    "subsequent years. In 2010, Godel Technologies invested in WSO2 for an unspecified amount,[14] and in 2012 the company " +
    "raised a third round of $10 million.[15][16] Official WSO2 records point to this being from Toba Capital, Cisco and " +
    "Intel Capital.[17] In August 2015, a funding round led by Pacific Controls and Toba raised another $20 million.[18][19]" +
    " The company gained recognition from a 2011 report in Information Week that eBay used WSO2 ESB as a key element of their" +
    " transaction-processing software.[20] Research firm Gartner noted that WSO2 was a leading competitor in the application " +
    "infrastructure market of 2014.[21] As of 2019, WSO2 has offices in: Mountain View, California; New York City; London, UK;" +
    " São Paulo, Brazil; Sydney, Australia; Berlin, Germany and Colombo, Sri Lanka. The bulk of its research and operations " +
    "are conducted from its main office in Colombo.[22] A subsidiary, WSO2Mobile, was launched in 2013, with Harsha Purasinghe" +
    " of Microimage as the CEO and co-founder.[23] In March 2015, WSO2.Telco was launched in partnership with Malaysian " +
    "telecommunications company Axiata,[24] which held a majority stake in the venture.[25] WSO2Mobile has since been " +
    "re-absorbed into its parent company. Historically, WSO2 has had a close connection to the Apache community, with " +
    "a significant portion of their products based on or contributing to the Apache product stack.[26] Likewise, many of " +
    "WSO2's top leadership have contributed to Apache projects. In 2013, WSO2 donated its Stratos project to Apache. ";

service class DefaultResponseInterceptor {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
       res.setHeader("default-response-interceptor", "true");
       ctx.set("last-interceptor", "default-response-interceptor");
       return ctx.next();
    }
}

service class ResponseInterceptorSetPayload {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
       res.setHeader("response-interceptor-setpayload", "true");
       res.setTextPayload("Text payload from response interceptor");
       ctx.set("last-interceptor", "response-interceptor-setpayload");
       return ctx.next();
    }
}

service class ResponseInterceptorWithoutCtxNext {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Response res) {
       res.setHeader("response-interceptor-without-ctx-next", "true");
       res.setHeader("last-interceptor", "response-interceptor-without-ctx-next");
       res.setTextPayload("Response from response interceptor");
    }
}

service class ResponseInterceptorCallerRespond {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Caller caller, http:Response res) returns error? {
        res.setHeader("response-interceptor-caller-respond", "true");
        res.setTextPayload("Response from caller inside response interceptor");
        check caller->respond(res);
    }
}

service class ResponseInterceptorCallerRespondError {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Caller caller) returns error? {
        ctx.set("last-interceptor", "response-interceptor-caller-respond-error");
        check caller->respond(error("Response interceptor returns an error"));
    }
}

service class ResponseInterceptorCallerRespondContinue {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Caller caller, http:Response res, http:RequestContext ctx) returns http:NextService|error? {
        res.setHeader("response-interceptor-caller-respond-continue", "true");
        res.setTextPayload("Response from caller inside response interceptor");
        check caller->respond(res);
        return ctx.next();
    }
}

service class ResponseInterceptorReturnsError {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns error {
       res.setHeader("response-interceptor-error", "true");
       ctx.set("last-interceptor", "response-interceptor-error");
       return error("Response interceptor returns an error");
    }
}

service class ResponseInterceptorSkip {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
       res.setHeader("skip-interceptor", "true");
       ctx.set("last-interceptor", "skip-interceptor");
       http:NextService|error? nextService = ctx.next();
       if nextService is error {
           return nextService;
       }
       return ctx.next();
    }
}

service class ResponseInterceptorWithVariable {
    *http:ResponseInterceptor;
    final string name;

    function init(string name) {
        self.name = name;
    }

    function getName() returns string {
        return self.name;
    }

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
       res.setHeader(self.getName(), "true");
       ctx.set("last-interceptor", self.getName());
       return ctx.next();
    }
}

service class LastResponseInterceptor {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:NextService|error? {
       string|error val = trap ctx.get("last-interceptor").ensureType(string);
       string header = val is string ? val : "last-response-interceptor";
       res.setHeader("last-response-interceptor", "true");
       res.setHeader("last-interceptor", header);
       val = trap ctx.get("error-type").ensureType(string);
       if val is string {
           res.setHeader("error-type", val);
       }
       return ctx.next();
    }
}

service class ResponseInterceptorReturnsResponse {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:RequestContext ctx, http:Response res) returns http:Response {
       res.setHeader("response-interceptor-returns-response", "true");
       ctx.set("last-interceptor", "response-interceptor-returns-response");
       string|error payloadVal = res.getTextPayload();
       string payload = payloadVal is string ? payloadVal : "";
       res.setTextPayload("Response from Interceptor : " + payload);
       return res;
    }
}

service class ResponseInterceptorReturnsStatusCodeResponse {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Response res) returns http:NotFound|http:Ok {
       boolean isHeaderPresent = res.getHeader("header") is string ? true : false;
       if isHeaderPresent {
           http:Ok ok = {
               body: "Response from Response Interceptor",
               headers: {
                   "last-interceptor" : "response-interceptor-returns-status"
               }
           };
           return ok;
       } else {
           http:NotFound nf = {
               body: "Header not found in response"
           };
           return nf;
       }
    }
}

service class DefaultResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError(error err, http:RequestContext ctx, http:Response res) returns http:NextService|error? {
       res.setHeader("default-response-error-interceptor", "true");
       res.setTextPayload(err.message());
       ctx.set("last-interceptor", "default-response-error-interceptor");
       ctx.set("error-type", getErrorType(err));
       return ctx.next();
    }
}

function getErrorType(error err) returns string {
    if err is http:InterceptorReturnError {
        return "InterceptorReturnError";
    } else if err is http:HeaderNotFoundError {
        return "HeaderNotFoundError";
    } else if err is http:HeaderBindingError {
        return "HeaderBindingError";
    } else if err is http:PathParameterBindingError {
        return "PathParamBindingError";
    } else if err is http:QueryParameterBindingError {
        return "QueryParamBindingError";
    } else if err is http:PayloadBindingError {
        return "PayloadBindingError";
    } else if err is http:RequestDispatchingError {
        if err is http:ServiceDispatchingError {
            return "DispatchingError-Service";
        } else {
            return "DispatchingError-Resource";
        }
    } else if err is http:ListenerAuthError {
        if err is http:ListenerAuthnError {
            return "ListenerAuthenticationError";
        } else {
            return "ListenerAuthorizationError";
        }
    } else {
        return "NormalError";
    }
}

service class ResponseInterceptorNegative1 {
    *http:ResponseInterceptor;

    remote function interceptResponse(http:Response res) returns http:ResponseInterceptor {
       return new DefaultResponseInterceptor();
    }
}

service class RequestIntercepterReturnsString {
    *http:RequestInterceptor;

    resource function post .(@http:Payload string payload) returns string {
        return payload;
    }
}
