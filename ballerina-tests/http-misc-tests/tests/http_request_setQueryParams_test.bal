import ballerina/http;
import ballerina/test;

// Test setting simple query parameters
@test:Config {}
function testSetQueryParamsSimple() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "name": ["john"],
        "age": ["25"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["name"], ["john"], msg = "Name parameter mismatch");
    test:assertEquals(retrievedParams["age"], ["25"], msg = "Age parameter mismatch");
    test:assertEquals(retrievedParams.length(), 2, msg = "Expected 2 query parameters");
}

// Test setting query parameters with multiple values
@test:Config {}
function testSetQueryParamsMultipleValues() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "color": ["red", "blue", "green"],
        "size": ["small", "large"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["color"], ["red", "blue", "green"], msg = "Color parameter mismatch");
    test:assertEquals(retrievedParams["size"], ["small", "large"], msg = "Size parameter mismatch");
}

// Test setting query parameters with special characters
@test:Config {}
function testSetQueryParamsSpecialCharacters() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "search": ["hello world"],
        "email": ["user@example.com"],
        "path": ["/home/user/file.txt"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["search"], ["hello world"], msg = "Search parameter mismatch");
    test:assertEquals(retrievedParams["email"], ["user@example.com"], msg = "Email parameter mismatch");
    test:assertEquals(retrievedParams["path"], ["/home/user/file.txt"], msg = "Path parameter mismatch");
}

// Test setting empty query parameters
@test:Config {}
function testSetQueryParamsEmpty() returns error? {
    http:Request req = new;
    
    // First set some params
    map<string[]> initialParams = {
        "name": ["john"]
    };
    req.setQueryParams(initialParams);
    
    // Then clear with empty map
    map<string[]> emptyParams = {};
    req.setQueryParams(emptyParams);
    
    map<string[]> retrievedParams = req.getQueryParams();
    test:assertEquals(retrievedParams.length(), 0, msg = "Expected no query parameters");
}

// Test replacing existing query parameters
@test:Config {}
function testSetQueryParamsReplace() returns error? {
    http:Request req = new;
    
    // Set initial params
    map<string[]> initialParams = {
        "name": ["john"],
        "age": ["25"]
    };
    req.setQueryParams(initialParams);
    
    // Replace with new params
    map<string[]> newParams = {
        "city": ["colombo"],
        "country": ["srilanka"]
    };
    req.setQueryParams(newParams);
    
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams.length(), 2, msg = "Expected 2 query parameters");
    test:assertEquals(retrievedParams["city"], ["colombo"], msg = "City parameter mismatch");
    test:assertEquals(retrievedParams["country"], ["srilanka"], msg = "Country parameter mismatch");
    test:assertFalse(retrievedParams.hasKey("name"), msg = "Old parameter should not exist");
    test:assertFalse(retrievedParams.hasKey("age"), msg = "Old parameter should not exist");
}

// Test setting query parameters and then retrieving specific values
@test:Config {}
function testSetQueryParamsGetValue() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "id": ["123"],
        "tags": ["tag1", "tag2", "tag3"]
    };
    
    req.setQueryParams(queryParams);
    
    string? idValue = req.getQueryParamValue("id");
    test:assertEquals(idValue, "123", msg = "ID value mismatch");
    
    string[]? tagValues = req.getQueryParamValues("tags");
    test:assertEquals(tagValues, ["tag1", "tag2", "tag3"], msg = "Tag values mismatch");
    
    string? nonExistent = req.getQueryParamValue("nonexistent");
    test:assertEquals(nonExistent, (), msg = "Non-existent parameter should return nil");
}

// Test setting query parameters with numeric values
@test:Config {}
function testSetQueryParamsNumericValues() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "page": ["1"],
        "limit": ["10"],
        "offset": ["100"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["page"], ["1"], msg = "Page parameter mismatch");
    test:assertEquals(retrievedParams["limit"], ["10"], msg = "Limit parameter mismatch");
    test:assertEquals(retrievedParams["offset"], ["100"], msg = "Offset parameter mismatch");
}

// Test setting query parameters with URL encoded characters
@test:Config {}
function testSetQueryParamsUrlEncoding() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "query": ["type=test&value=123"],
        "redirect": ["https://example.com?page=1"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["query"], ["type=test&value=123"], msg = "Query parameter mismatch");
    test:assertEquals(retrievedParams["redirect"], ["https://example.com?page=1"], msg = "Redirect parameter mismatch");
}

// Test setting query parameters with unicode characters
@test:Config {}
function testSetQueryParamsUnicode() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "name": ["José"],
        "city": ["São Paulo"],
        "greeting": ["Hello 世界"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["name"], ["José"], msg = "Name parameter mismatch");
    test:assertEquals(retrievedParams["city"], ["São Paulo"], msg = "City parameter mismatch");
    test:assertEquals(retrievedParams["greeting"], ["Hello 世界"], msg = "Greeting parameter mismatch");
}

// Test setting query parameters multiple times
@test:Config {}
function testSetQueryParamsMultipleTimes() returns error? {
    http:Request req = new;
    
    // First set
    map<string[]> params1 = {"key1": ["value1"]};
    req.setQueryParams(params1);
    test:assertEquals(req.getQueryParamValue("key1"), "value1", msg = "First set failed");
    
    // Second set
    map<string[]> params2 = {"key2": ["value2"]};
    req.setQueryParams(params2);
    test:assertEquals(req.getQueryParamValue("key2"), "value2", msg = "Second set failed");
    test:assertEquals(req.getQueryParamValue("key1"), (), msg = "First key should be replaced");
    
    // Third set
    map<string[]> params3 = {"key3": ["value3"]};
    req.setQueryParams(params3);
    test:assertEquals(req.getQueryParamValue("key3"), "value3", msg = "Third set failed");
    test:assertEquals(req.getQueryParamValue("key2"), (), msg = "Second key should be replaced");
}

// Test setting query parameters with empty values
@test:Config {}
function testSetQueryParamsEmptyValues() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "empty": [""],
        "nonempty": ["value"]
    };
    
    req.setQueryParams(queryParams);
    map<string[]> retrievedParams = req.getQueryParams();
    
    test:assertEquals(retrievedParams["empty"], [""], msg = "Empty value parameter mismatch");
    test:assertEquals(retrievedParams["nonempty"], ["value"], msg = "Non-empty value parameter mismatch");
}

// Test setting query parameters and checking consistency
@test:Config {}
function testSetQueryParamsConsistency() returns error? {
    http:Request req = new;
    
    map<string[]> queryParams = {
        "filter": ["active"],
        "sort": ["name", "date"],
        "page": ["1"]
    };
    
    req.setQueryParams(queryParams);
    
    // Retrieve multiple times to ensure consistency
    map<string[]> retrieved1 = req.getQueryParams();
    map<string[]> retrieved2 = req.getQueryParams();
    
    test:assertEquals(retrieved1, retrieved2, msg = "Retrieved parameters should be consistent");
    test:assertEquals(retrieved1["filter"], ["active"], msg = "Filter parameter mismatch");
    test:assertEquals(retrieved1["sort"], ["name", "date"], msg = "Sort parameter mismatch");
    test:assertEquals(retrieved1["page"], ["1"], msg = "Page parameter mismatch");
}
