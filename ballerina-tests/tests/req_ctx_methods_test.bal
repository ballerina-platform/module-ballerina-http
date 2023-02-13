import ballerina/test;
import ballerina/http;

@test:Config {}
function testReqCtxHasKeySuccess() {
    http:RequestContext reqCtx = new;
    reqCtx.set("key", "value");
    test:assertTrue(reqCtx.hasKey("key"), msg = "Failed to check if the key exists");
}

@test:Config {}
function testReqCtxHasKeyFailure() {
    http:RequestContext reqCtx = new;
    test:assertFalse(reqCtx.hasKey("key"), msg = "Failed to check if the key exists");
}

@test:Config {}
function testReqCtxKeysSuccess() {
    http:RequestContext reqCtx = new;
    test:assertEquals(reqCtx.keys(), [], msg = "Failed to get the keys");
    reqCtx.set("key1", "value1");
    test:assertEquals(reqCtx.keys(), ["key1"], msg = "Failed to get the keys");
    reqCtx.set("key2", "value2");
    test:assertEquals(reqCtx.keys(), ["key1", "key2"], msg = "Failed to get the keys");
}

@test:Config {}
function testReqCtxGetSuccess() returns error? {
    http:RequestContext reqCtx = new;
    reqCtx.set("key", "value");
    test:assertEquals(reqCtx.get("key"), "value", msg = "Failed to get the value");

    string value = check reqCtx.get("key").ensureType();
    test:assertEquals(value, "value", msg = "Failed to get the value");
}

@test:Config {}
function testReqCtxGetFailure() {
    http:RequestContext reqCtx = new;
    string|error value1 = trap reqCtx.get("key").ensureType();
    test:assertTrue(value1 is error, msg = "Unexpected value returned");

    reqCtx.set("key", "value");
    int|error value2 = trap reqCtx.get("key").ensureType();
    test:assertTrue(value2 is error, msg = "Unexpected value returned");
}

@test:Config {}
function testReqCtxGetWithTypeSuccess() returns error? {
    http:RequestContext reqCtx = new;
    reqCtx.set("key", "value");
    string value = check reqCtx.getWithType("key");
    test:assertEquals(value, "value", msg = "Failed to get the value with type");

    User user = {id: 1, age: 25};
    reqCtx.set("user", user);
    User user1 = check reqCtx.getWithType("user");
    test:assertEquals(user1, user, msg = "Failed to get the value with type");
}

@test:Config {}
function testReqCtxGetWithTypeFailure() {
    http:RequestContext reqCtx = new;
    string|error value1 = reqCtx.getWithType("key");
    test:assertTrue(value1 is error, msg = "Unexpected value returned");

    reqCtx.set("key", "value");
    User|error value2 = reqCtx.getWithType("key");
    test:assertTrue(value2 is error, msg = "Unexpected value returned");
}

@test:Config {}
function testReqCtxRemoveSuccess() {
    http:RequestContext reqCtx = new;
    reqCtx.set("key", "value");
    test:assertTrue(reqCtx.hasKey("key"), msg = "Failed to check if the key exists");
    reqCtx.remove("key");
    test:assertFalse(reqCtx.hasKey("key"), msg = "Failed to check if the key exists");
}

@test:Config {}
function testReqCtxRemoveFailure() {
    http:RequestContext reqCtx = new;
    error? value = trap reqCtx.remove("key");
    test:assertTrue(value is error, msg = "Unexpected value returned");
}
