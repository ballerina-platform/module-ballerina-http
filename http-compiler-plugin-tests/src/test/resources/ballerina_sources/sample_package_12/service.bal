import ballerina/http;

service http:Service on new http:Listener(9090) {

    resource function get multiple1(@http:CallerInfo {respondType:string} http:Caller abc, http:Request req,
            http:Headers head, http:Caller xyz, http:Headers noo, http:Request aaa) {
        checkpanic xyz->respond("done");
    }

    resource function get multiple2(http:Caller abc, @http:CallerInfo http:Caller ccc) {
    }

    resource function get multiple3(http:Request abc, @http:CallerInfo http:Caller ccc, http:Request fwdw) {
    }

    resource function get multiple4(http:Headers abc, http:Headers ccc) {
    }
}
