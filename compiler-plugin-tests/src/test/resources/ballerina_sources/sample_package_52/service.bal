import ballerina/http;

service class PlainInterceptor {
    *http:RequestInterceptor;
}

isolated service class IsolatedInterceptor {
    *http:RequestInterceptor;
}

distinct service class DistinctInterceptor {
    *http:RequestInterceptor;
}