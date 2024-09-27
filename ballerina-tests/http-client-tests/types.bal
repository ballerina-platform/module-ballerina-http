import ballerina/data.jsondata;

public type TPerson record {
    @jsondata:Name {
        value: "name"
    }
    string firstName;
    @jsondata:Name {
        value: "age"
    }
    string personAge;
};

public type OKPerson record {|
    *http:Ok;
    TPerson body;
|};