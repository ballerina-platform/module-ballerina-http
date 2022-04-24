package io.ballerina.stdlib.http.testutils;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BXml;


public class ExternHttp3Client {

    public static Object sendGetRequest(int port,BString path) throws Exception {

        BMap<BString, Object> response = Http3Client.start(port, "get",  path.toString(), null);
        return StringUtils.fromString(String.valueOf(response));
    }

    public static Object sendPostRequestWithStringPayload(int port, BString path, BString payload) throws Exception {

        BMap<BString, Object>response = Http3Client.start(port, "post",  path.toString(), payload.toString());
        return StringUtils.fromString(String.valueOf(response));
//        return response;

    }

    public static Object sendPostRequestWithJsonPayload(int port, BString path, BMap payload) throws Exception {

        BMap<String, Object> data = (BMap<String, Object>) payload;
        BMap<BString, Object> response = Http3Client.start(port, "post",  path.toString(), data);
        return StringUtils.fromString(String.valueOf(response));
//        return response;
    }

    public static Object sendPostRequestWithXmlPayload(int port, BString path, BXml payload) throws Exception {

        BMap<BString, Object>  response = Http3Client.start(port, "post",  path.toString(), payload);
        return StringUtils.fromString(String.valueOf(response));
    }
}
