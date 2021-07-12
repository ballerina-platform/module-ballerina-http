/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.http;

import org.ballerinalang.net.uri.URITemplateException;
import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * A unit test class for http module Exception class.
 */
public class ExceptionTest {
    @Test
    public void testBallerinaConnectorException() {
        Throwable throwable = new Throwable("This is a throwable");
        BallerinaConnectorException exception = new BallerinaConnectorException("error", throwable);

        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getCause().getMessage(), "This is a throwable");
    }

    @Test
    public void testURITemplateException() {
        URITemplateException exception = new URITemplateException("error");

        Assert.assertEquals(exception.getMessage(), "error");
    }

    @Test
    public void testURITemplateExceptionWithThrowable() {
        Throwable throwable = new Throwable("This is a throwable");
        URITemplateException exception = new URITemplateException("error", throwable);

        Assert.assertEquals(exception.getMessage(), "error");
        Assert.assertEquals(exception.getCause().getMessage(), "This is a throwable");
    }
}
