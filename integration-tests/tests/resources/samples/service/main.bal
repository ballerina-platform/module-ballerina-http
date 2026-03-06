import ballerina/http;

public type Album readonly & record {|
    string title;
    string artist;
|};

final table<Album> key(title) albums = table [
    {title: "Blue Train", artist: "John Coltrane"},
    {title: "Jeru", artist: "Gerry Mulligan"}
];

listener http:Listener 'listener = new(9797);
service / on 'listener {

    isolated resource function get albums() returns Album[] {
        return albums.toArray();
    }
}
