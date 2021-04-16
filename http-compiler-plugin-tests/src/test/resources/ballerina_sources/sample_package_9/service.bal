import ballerina/http;

listener http:Listener ep1 = new(9091);
listener http:Listener ep2 = new(9092, { httpVersion: "2.0" });
listener http:Listener ep3 = new(9095);

service http:Service on ep1 {
    remote function greeting(http:Caller caller) {
    }
}

service http:Service on ep2, ep3 {
    remote function greeting(http:Caller caller) {
    }
}

service http:Service on new http:Listener(9093) {
    resource function get greeting() {
    }
}

service on new http:Listener(9094, { host: "0.0.0.0"}), new http:Listener(9096) {
    resource function get greeting() {
    }
}
