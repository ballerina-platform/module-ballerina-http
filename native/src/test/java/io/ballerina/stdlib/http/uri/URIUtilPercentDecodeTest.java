/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.uri;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import static org.testng.Assert.assertEquals;

/**
 * Tests for the shared percent-decoder.
 */
public class URIUtilPercentDecodeTest {

    @Test(description = "Plus is kept for path segments and converted to a space for query values")
    public void testPlusHandling() {
        assertEquals(URIUtil.percentDecode("a+b", false), "a+b");
        assertEquals(URIUtil.percentDecode("a+b", true), "a b");
        assertEquals(URIUtil.percentDecode("a%2Bb", true), "a+b");
    }

    @Test(description = "A value is decoded exactly once, including multi-byte UTF-8")
    public void testDecodedOnce() {
        assertEquals(URIUtil.percentDecode("%2520", false), "%20");
        assertEquals(URIUtil.percentDecode("caf%C3%A9", false), "café");
        assertEquals(URIUtil.percentDecode("café", false), "café");
    }

    @DataProvider(name = "malformed")
    public Object[][] malformed() {
        return new Object[][]{{"%"}, {"%z"}, {"%zz"}, {"a%2"}, {"%2g"}, {"100%"}, {"%FF"}, {"%C0%AE"}, {"%E9"}};
    }

    @Test(dataProvider = "malformed", expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "malformed percent-encoding in the request target",
            description = "A malformed escape is rejected with a clean message")
    public void testMalformedEscape(String value) {
        URIUtil.percentDecode(value, false);
    }
}
