import ballerina/http;

service class DefaultRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("default-interceptor", "true");
       ctx.add("last-interceptor", "default-interceptor");
       return ctx.next();
    }
}

service class DataBindingRequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, @http:Payload string payload, @http:Header {name: "interceptor"} string header) returns http:NextService|error? {
       ctx.add("request-payload", payload);
       ctx.add("last-interceptor", header);
       return ctx.next();
    }
}

service class RequestInterceptorSetPayload {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns http:NextService|error? {
       req.setHeader("interceptor-setpayload", "true");
       req.setTextPayload("Text payload from interceptor");
       ctx.add("last-interceptor", "interceptor-setpayload");
       return ctx.next();
    }
}

service class RequestInterceptorCallerRepond {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:Caller caller, http:Request request) returns error? {
        http:Response res = new();
        res.setHeader("last-interceptor", "request-interceptor-caller-repond");
        res.setTextPayload("Response from caller inside interceptor");
        check caller->respond(res);
    }
}

service class RequestInterceptorCallerRepondContinue {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Caller caller, http:Request request) returns http:NextService|error? {
        http:Response res = new();
        res.setHeader("last-interceptor", "request-interceptor-caller-repond");
        res.setTextPayload("Response from caller inside interceptor");
        check caller->respond(res);
        return ctx.next();
    }
}

service class RequestInterceptorReturnsError {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) returns error {
       req.setHeader("request-interceptor-error", "true");
       ctx.add("last-interceptor", "request-interceptor-error");
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

service class DefaultRequestErrorInterceptor {
    *http:RequestErrorInterceptor;
    int foo = 100;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req, error err) returns http:NextService|error? {
       req.setHeader("default-error-interceptor", "true");
       req.setTextPayload(err.message());
       ctx.add("last-interceptor", "default-error-interceptor");
       return ctx.next();
    }
}

service class RequestInterceptorWithoutCtxNext {
    *http:RequestInterceptor;

    resource function 'default [string... path](http:RequestContext ctx, http:Request req) {
       req.setHeader("request-interceptor-without-ctx-next", "true");
       ctx.add("last-interceptor", "request-interceptor-without-ctx-next");
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
