import ballerina/http;

public type Album readonly & record {|
    string title;
    string artist;
|};

final table<Album> key(title) albums = table [
    {title: "Blue Train", artist: "John Coltrane"},
    {title: "Jeru", artist: "Gerry Mulligan"}
];

configurable int port = 9797;

listener http:Listener 'listener = new(port);

// Calls this service's own `/albums` resource, so that a request to `/upstream/albums` makes an upstream call.
final http:Client upstreamClient = check new (string `http://localhost:${port}`);

service / on 'listener {

    isolated resource function get albums() returns Album[] {
        return albums.toArray();
    }

    // Forwards the request, with its headers, to `/albums`. The access log line of the request then has an
    // upstream entry for the forwarded call.
    isolated resource function get upstream/albums(http:Request request) returns http:Response|error {
        http:Response response = check upstreamClient->forward("/albums", request);
        return response;
    }
}
