package io.ballerina.stdlib.http.testutils;

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BXml;

import java.util.Map;

import static io.ballerina.runtime.api.PredefinedTypes.TYPE_STRING;


public class ExternHttp3Client {

    private static final MapType mapType = TypeCreator.createMapType(
            TypeCreator.createArrayType(TYPE_STRING));

    public static Object sendGetRequest(int port, BString path) throws Exception {

        BMap<BString, Object> res = ValueCreator.createMapValue(mapType);
        BMap<BString, Object> response = Http3Client.start(port, "get", path.toString(), null);
        for (Map.Entry<BString, Object> entry : response.entrySet()) {
            res.put(entry.getKey(), entry.getValue());
        }
        return res;
    }

    public static Object sendPostRequestWithStringPayload(int port, BString path, BString payload) throws Exception {

        BMap<BString, Object> res = ValueCreator.createMapValue(mapType);
        BMap<BString, Object> response = Http3Client.start(port, "post", path.toString(), payload.toString());
        for (Map.Entry<BString, Object> entry : response.entrySet()) {
            res.put(entry.getKey(), entry.getValue());
        }
        return res;

    }

    public static Object sendPostRequestWithJsonPayload(int port, BString path, BMap payload) throws Exception {

        BMap<String, Object> data = (BMap<String, Object>) payload;
        BMap<BString, Object> res = ValueCreator.createMapValue(mapType);
        BMap<BString, Object> response = Http3Client.start(port, "post", path.toString(), data);
        for (Map.Entry<BString, Object> entry : response.entrySet()) {
            res.put(entry.getKey(), entry.getValue());
        }
        return res;
    }

    public static Object sendPostRequestWithXmlPayload(int port, BString path, BXml payload) throws Exception {

        BMap<BString, Object> res = ValueCreator.createMapValue(mapType);
        BMap<BString, Object> response = Http3Client.start(port, "post", path.toString(), payload);
        for (Map.Entry<BString, Object> entry : response.entrySet()) {
            res.put(entry.getKey(), entry.getValue());
        }
        return res;
    }
}
