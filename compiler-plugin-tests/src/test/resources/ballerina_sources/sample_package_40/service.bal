import ballerina/http;

type ContractServiceWithoutServiceConfig service object {
    *http:ServiceContract;
};

@http:ServiceConfig {
    basePath: "/api"
}
type ContractService service object {
    *http:ServiceContract;
};

@http:ServiceConfig {
}
service ContractService /api on new http:Listener(9090) {
};

@http:ServiceConfig {
    serviceType:  ContractService
}
service ContractService on new http:Listener(9090) {
};

@http:ServiceConfig {
    basePath: "/api"
}
type NonContractService service object {
    *http:Service;
};

@http:ServiceConfig {
    serviceType:  ContractServiceWithoutServiceConfig
}
service ContractService on new http:Listener(9090) {
};

@http:ServiceConfig {
    serviceType:  ContractServiceWithoutServiceConfig
}
service NonContractService on new http:Listener(9090) {
};


@http:ServiceConfig {
    basePath: "/api"
}
type ContractServiceWithResource service object {
    *http:ServiceContract;

    resource function get greeting(@http:Header string? header) returns string;
};

service ContractServiceWithResource on new http:Listener(9090) {
    resource function get greeting(string? header) returns string {
        return "Hello, World!";
    }
};

service ContractServiceWithResource on new http:Listener(9090) {
    resource function get greeting(string? header) returns string {
        return "Hello, World!";
    }

    resource function get newGreeting() {}
};

service ContractServiceWithResource on new http:Listener(9090) {

    @http:ResourceConfig {}
    resource function get greeting(@http:Header string? header) returns string {
        return "Hello, World!";
    }
};
