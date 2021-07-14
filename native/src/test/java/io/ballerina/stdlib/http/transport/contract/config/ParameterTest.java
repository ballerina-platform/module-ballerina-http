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

package io.ballerina.stdlib.http.transport.contract.config;

import org.testng.Assert;
import org.testng.annotations.Test;

/**
 * A unit test class for Transport module Parameter class functions.
 */
public class ParameterTest {

    @Test
    public void testGetName() {
        Parameter parameter = new Parameter();
        Assert.assertNull(parameter.getName());
        parameter.setName("testName1");
        Assert.assertEquals(parameter.getName(), "testName1");

        parameter = new Parameter("testName2", "testValue");
        Assert.assertEquals(parameter.getName(), "testName2");
    }

    @Test
    public void testGetValue() {
        Parameter parameter = new Parameter();
        Assert.assertNull(parameter.getValue());
        parameter.setValue("testValue1");
        Assert.assertEquals(parameter.getValue(), "testValue1");

        parameter = new Parameter("testName", "testValue2");
        Assert.assertEquals(parameter.getValue(), "testValue2");
    }

}
