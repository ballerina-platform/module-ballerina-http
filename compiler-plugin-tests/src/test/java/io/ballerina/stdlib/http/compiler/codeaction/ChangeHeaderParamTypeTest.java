/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.compiler.codeaction;

import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.io.IOException;

/**
 * Tests the change return type to 'error?' when http:Caller is a function parameter.
 */
public class ChangeHeaderParamTypeTest extends AbstractCodeActionTest {

    @Test(dataProvider = "testDataProvider")
    public void testCodeActions(String configName) throws IOException {
        performTest(configName);
    }

    @DataProvider
    private Object[][] testDataProvider() {
        return new String[][]{
                {"config1.json"}
        };
    }

    @Override
    protected String getConfigDir() {
        return "change_header_param_type";
    }
}
