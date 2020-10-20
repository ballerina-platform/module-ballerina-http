/*
 *  Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.net.testutils;

import io.ballerina.runtime.api.values.BString;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.util.internal.PlatformDependent;
import io.netty.util.internal.StringUtil;
import org.ballerinalang.net.testutils.client.HttpUrlClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Contains utility functions used for the retry test.
 */
public class ExternRetryMultipartTestutil {

    private static final Logger log = LoggerFactory.getLogger(ExternRetryMultipartTestutil.class);
    private static final String RETRY_HEADER = "x-retry";

    //Test retry functionality with multipart requests
    public static boolean externTestMultiPart(int servicePort, BString path) {
        String multipartDataBoundary = Long.toHexString(PlatformDependent.threadLocalRandom().nextLong());
        String multipartBody = "--" + multipartDataBoundary + "\r\n" +
                "Content-Disposition: form-data; name=\"foo\"" + "\r\n" +
                "Content-Type: text/plain; charset=UTF-8" + "\r\n" +
                "\r\n" +
                "Part1" +
                "\r\n" +
                "--" + multipartDataBoundary + "\r\n" +
                "Content-Disposition: form-data; name=\"filepart\"; filename=\"file-01.txt\"" + "\r\n" +
                "Content-Type: text/plain" + "\r\n" +
                "Content-Transfer-Encoding: binary" + "\r\n" +
                "\r\n" +
                "Part2" + StringUtil.NEWLINE +
                "\r\n" +
                "--" + multipartDataBoundary + "--" + "\r\n";
        Map<String, String> headers = new HashMap<>();
        headers.put(HttpHeaderNames.CONTENT_TYPE.toString(), "multipart/form-data; boundary=" + multipartDataBoundary);
        HttpResponse response;
        try {
            response = HttpUrlClient.doPost(HttpUrlClient.getServiceURLHttp(servicePort, path.getValue()),
                                            multipartBody, headers);
        } catch (IOException e) {
            log.error("Error in processing request" + e.getMessage());
            return false;
        }
        Assert.assertEquals(response.getResponseCode(), 200, "Response code mismatched");
        Assert.assertTrue(response.getHeaders().get(HttpHeaderNames.CONTENT_TYPE.toString())
                        .contains("multipart/form-data;boundary=" + multipartDataBoundary),
                "Response is not form of multipart");
        Assert.assertTrue(response.getData().contains("content-disposition: form-data;name=\"foo\"content-type: " +
                "text/plain;charset=UTF-8content-id: 0Part1"), "Message content mismatched");
        Assert.assertTrue(response.getData().contains("content-disposition: form-data;name=\"filepart\";" +
                "filename=\"file-01.txt\"content-type: text/plaincontent-transfer-encoding: binarycontent-id: 1Part2"),
                "Message content mismatched");
        return true;
    }

    //Test retry functionality when request has nested body parts")
    public static boolean externTestNestedMultiPart(int servicePort, BString path) {
        String multipartDataBoundary = Long.toHexString(PlatformDependent.threadLocalRandom().nextLong());
        String multipartMixedBoundary = Long.toHexString(PlatformDependent.threadLocalRandom().nextLong());
        String nestedMultipartBody = "--" + multipartDataBoundary + "\r\n" +
                "Content-Disposition: form-data; name=\"parent1\"" + "\r\n" +
                "Content-Type: text/plain; charset=UTF-8" + "\r\n" +
                "\r\n" +
                "Parent Part" + "\r\n" +
                "--" + multipartDataBoundary + "\r\n" +
                "Content-Disposition: form-data; name=\"parent2\"" + "\r\n" +
                "Content-Type: multipart/mixed; boundary=" + multipartMixedBoundary + "\r\n" +
                "\r\n" +
                "--" + multipartMixedBoundary + "\r\n" +
                "Content-Disposition: attachment; filename=\"file-02.txt\"" + "\r\n" +
                "Content-Type: text/plain" + "\r\n" +
                "Content-Transfer-Encoding: binary" + "\r\n" +
                "\r\n" +
                "Child Part 1" + StringUtil.NEWLINE +
                "\r\n" +
                "--" + multipartMixedBoundary + "\r\n" +
                "Content-Disposition: attachment; filename=\"file-02.txt\"" + "\r\n" +
                "Content-Type: text/plain" + "\r\n" +
                "Content-Transfer-Encoding: binary" + "\r\n" +
                "\r\n" +
                "Child Part 2" + StringUtil.NEWLINE +
                "\r\n" +
                "--" + multipartMixedBoundary + "--" + "\r\n" +
                "--" + multipartDataBoundary + "--" + "\r\n";

        String expectedChildPart1 = "content-disposition: attachment;" +
                "filename=\"file-02.txt\"" +
                "content-type: text/plain" +
                "content-transfer-encoding: binary" +
                "content-id: 0" +
                "Child Part 1";
        String expectedChildPart2 = "content-disposition: attachment;" +
                "filename=\"file-02.txt\"" +
                "content-type: text/plain" +
                "content-transfer-encoding: binary" +
                "content-id: 1" +
                "Child Part 2";
        Map<String, String> headers = new HashMap<>();
        headers.put(HttpHeaderNames.CONTENT_TYPE.toString(), "multipart/form-data; boundary=" + multipartDataBoundary);
        HttpResponse response = null;
        try {
            response = HttpUrlClient.doPost(HttpUrlClient.getServiceURLHttp(servicePort, path.getValue()),
                                            nestedMultipartBody, headers);
        } catch (IOException e) {
            log.error("Error in processing request" + e.getMessage());
            return false;
        }
        Assert.assertEquals(response.getResponseCode(), 200, "Response code mismatched");
        Assert.assertTrue(response.getHeaders().get(HttpHeaderNames.CONTENT_TYPE.toString())
                        .contains("multipart/form-data;boundary=" + multipartDataBoundary),
                "Response is not form of multipart");
        Assert.assertTrue(response.getData().contains(expectedChildPart1), "Message content mismatched");
        Assert.assertTrue(response.getData().contains(expectedChildPart2), "Message content mismatched");
        return true;
    }
}
