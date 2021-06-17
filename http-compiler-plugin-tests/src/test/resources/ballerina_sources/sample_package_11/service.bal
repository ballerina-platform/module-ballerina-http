import ballerina/http;
import ballerina/mime;
import ballerina/io;

type RetEmployee record {|
    readonly int id;
    string name;
|};

type PersonTable table<RetEmployee> key(id);
type Xml xml;
type ByteArr byte[];
type MapJson map<json>;
type MapJsonArr map<json>[];
type EntityArr mime:Entity[];
type PersonTableArr PersonTable[];
type ByteStream stream<byte[], io:Error?>;

service http:Service on new http:Listener(9090) {
    resource function get callerInfo17(int xyz, @http:CallerInfo {respondType: http:Response} http:Caller abc) {
        http:Response res = new;
        checkpanic abc->respond(res);
    }

    resource function get callerInfo18(int xyz, @http:CallerInfo {respondType: http:Response} http:Caller abc) {
        checkpanic abc->respond("res"); // error
    }

    resource function get callerInfo20(int xyz, @http:CallerInfo {respondType: Xml} http:Caller abc) {
        xml x = xml `<book>Hello World</book>`;
        checkpanic abc->respond(x);
    }

    resource function get callerInfo21(int xyz, @http:CallerInfo {respondType: Xml} http:Caller abc) {
        checkpanic abc->respond("res"); // error
    }

    resource function get callerInfo2_2(int xyz, @http:CallerInfo {respondType: json} http:Caller abc) {
        json j = {hello: "world"};
        checkpanic abc->respond(j);
    }

    resource function get callerInfo22(int xyz, @http:CallerInfo {respondType: json} http:Caller abc) {
        checkpanic abc->respond({hello: "world"}); // this is also fails and a limitation for inline json
    }

    resource function get callerInfo23(int xyz, @http:CallerInfo {respondType: json} http:Caller abc) {
        http:Response res = new;
        checkpanic abc->respond(res); // error
    }

    resource function get callerInfo24(int xyz, @http:CallerInfo {respondType: ByteArr} http:Caller abc) {
        checkpanic abc->respond("Sample Text".toBytes());
    }

    resource function get callerInfo25(int xyz, @http:CallerInfo {respondType: ByteArr} http:Caller abc) {
        http:Response res = new;
        checkpanic abc->respond(res); // error
    }

    resource function get callerInfo26(int xyz, @http:CallerInfo {respondType: MapJson} http:Caller abc) {
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        checkpanic abc->respond(jj);
    }

    resource function get callerInfo27(int xyz, @http:CallerInfo {respondType: MapJson} http:Caller abc) {
        http:Response res = new;
        checkpanic abc->respond(res); // error
    }

    resource function get callerInfo28(int xyz, @http:CallerInfo {respondType: PersonTable} http:Caller abc) {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        checkpanic abc->respond(tbPerson);
    }

    resource function get callerInfo29(int xyz, @http:CallerInfo {respondType: PersonTable} http:Caller abc) {
        checkpanic abc->respond("res"); // error
    }

    resource function get callerInfo30(int xyz, @http:CallerInfo {respondType: MapJsonArr} http:Caller abc) {
        map<json> jj = {sam: {hello:"world"}, jon: {no:56}};
        map<json>[] arr = [jj, jj];
        checkpanic abc->respond(arr);
    }

    resource function get callerInfo31(int xyz, @http:CallerInfo {respondType: MapJsonArr} http:Caller abc) {
        http:Response res = new;
        checkpanic abc->respond(res); // error
    }

    resource function get callerInfo32(int xyz, @http:CallerInfo {respondType: PersonTableArr} http:Caller abc) {
        PersonTable tbPerson = table [
            {id: 1, name: "John"},
            {id: 2, name: "Bella"}
        ];
        PersonTableArr arr = [tbPerson, tbPerson];
        checkpanic abc->respond(arr);
    }

    resource function get callerInfo33(int xyz, @http:CallerInfo {respondType: PersonTableArr} http:Caller abc) {
        checkpanic abc->respond("res"); // error
    }

    resource function get callerInfo34(int xyz, @http:CallerInfo {respondType: EntityArr} http:Caller abc) {
        mime:Entity bodyPart = new;
        bodyPart.setJson({"bodyPart":"jsonPart"});
        checkpanic abc->respond([bodyPart, bodyPart]);
    }

    resource function get callerInfo35(int xyz, @http:CallerInfo {respondType: EntityArr} http:Caller abc) {
        checkpanic abc->respond("res"); // error
    }

    resource function get callerInfo36(http:Request request,
            @http:CallerInfo {respondType: ByteStream} http:Caller abc) {
        var str = request.getByteStream();
        if (str is stream<byte[], io:Error?>) {
            error? err = abc->respond(str);
        }
    }

    resource function get callerInfo37(@http:CallerInfo {respondType: ByteStream} http:Caller abc) {
        checkpanic abc->respond("res"); // error
    }
}
