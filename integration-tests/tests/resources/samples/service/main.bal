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
service / on 'listener {

    isolated resource function get albums() returns Album[] {
        return albums.toArray();
    }
}
