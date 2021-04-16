import ballerina/http;
import ballerina/file;

listener http:Listener ep1 = new(9091);
listener http:Listener ep2 = new(9092, { httpVersion: "2.0" });
listener http:Listener ep3 = new(9095);
listener file:Listener inFolder = new ({
    path: "/home/ballerina/fs-server-connector/observed-dir",
    recursive: false
});

service http:Service on ep1 {
    resource function get greeting(http:Caller caller) {
    }
}

service http:Service on ep2, ep3 {
    resource function get greeting(http:Caller caller) {
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

service http:Service on ep2, inFolder { // error
    resource function get greeting(http:Response res) {
    }
}

service http:Service on inFolder { // skip http validation
    remote function greeting(http:Cookie abc) {
    }
}
