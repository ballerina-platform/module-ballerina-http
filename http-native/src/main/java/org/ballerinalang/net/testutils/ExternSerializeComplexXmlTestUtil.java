/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import io.netty.handler.codec.http.HttpHeaderNames;
import org.ballerinalang.net.testutils.client.HttpUrlClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;

import static io.ballerina.runtime.api.utils.XmlUtils.parse;

/**
 * Contains utility functions used for XML Serialization Test case.
 */
public class ExternSerializeComplexXmlTestUtil {

    private static final Logger log = LoggerFactory.getLogger(ExternSerializeComplexXmlTestUtil.class);

    public static boolean externTestXmlSerialization(int servicePort) {
        try {
            HttpResponse response = HttpUrlClient.doGetAndPreserveNewlineInResponseData(
                    HttpUrlClient.getServiceURLHttp(servicePort, "serialize/xml"));
            Assert.assertEquals(response.getResponseCode(), 200, "Response code mismatched");
            Assert.assertEquals(response.getHeaders().get(HttpHeaderNames.CONTENT_TYPE.toString()),
                                TestConstant.CONTENT_TYPE_XML, "Content-Type mismatched");
            Assert.assertEquals(parse(getInputStream()), parse(response.getData()), "Message content mismatched");
        } catch (IOException e) {
            log.error("Error in processing request" + e.getMessage());
            return false;
        }
        return true;
    }

    private static InputStream getInputStream() throws IOException {
        String filePath = Paths.get("tests/datafiles/ComplexTestXmlSample.xml")
                .toAbsolutePath().toString();
        return new FileInputStream(filePath);
    }
}
