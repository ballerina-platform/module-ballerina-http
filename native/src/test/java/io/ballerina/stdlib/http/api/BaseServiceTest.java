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

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.values.BObject;
import org.apache.commons.io.FileUtils;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;

/**
 * A unit test class for http module {@link BaseService} class functions.
 */
public class BaseServiceTest {

    @Test
    public void testKeepAlive() {
        BObject service = TestUtils.getNewServiceObject("hello");
        BaseService baseService = new BaseService(service);
        Assert.assertTrue(baseService.isKeepAlive());

        baseService.setKeepAlive(false);
        Assert.assertFalse(baseService.isKeepAlive());
    }

    @Test
    public void testNullServiceBasePath() {
        BObject service = TestUtils.getNewServiceObject("hello");
        BaseService baseService = new BaseService(service);
        baseService.setBasePath(null);

        Assert.assertEquals(baseService.getBasePath(), "/hello");

        service = TestUtils.getNewServiceObject("$hello");
        baseService = new BaseService(service);
        baseService.setBasePath(null);

        Assert.assertEquals(baseService.getBasePath(), "/");
    }

    @Test
    public void testEmptyNullServiceBasePath() {
        BObject service = TestUtils.getNewServiceObject("hello");
        BaseService baseService = new BaseService(service);
        baseService.setBasePath(" ");

        Assert.assertEquals(baseService.getBasePath(), "/hello");
    }

    @Test
    public void testNotNullServiceBasePath() {
        BObject service = TestUtils.getNewServiceObject("hello");
        BaseService baseService = new BaseService(service);
        baseService.setBasePath("ballerina");

        Assert.assertEquals(baseService.getBasePath(), "/ballerina");
    }

    @Test
    public void testGetPayloadFunctionOfIntrospectionResource() {
        BObject service = TestUtils.getNewServiceObject("hello");
        BaseService baseService = new BaseService(service);
        String filePath = "resources/ballerina/http/testopenapidoc.json";
        HttpIntrospectionResource introspectionResource = new HttpIntrospectionResource(baseService, filePath);
        byte[] payload = introspectionResource.getPayload();
        byte[] fileContent = new byte[0];
        try {
            Path resourceDirectory = Paths.get("src", "test", "resources");
            String absolutePath = resourceDirectory.toFile().getAbsolutePath();
            fileContent = FileUtils.readFileToByteArray(
                    new File(absolutePath + "/resources/ballerina/http/testopenapidoc.json"));
        } catch (IOException e) {
            Assert.fail("testopenapidoc read failure" + e.getMessage());
        }
        Assert.assertTrue(Arrays.equals(payload, fileContent));
    }

    @Test
    public void testGetIntrospectionResourceIdOfIntrospectionResource() {
        Assert.assertEquals(HttpIntrospectionResource.getIntrospectionResourceId(), "$get$openapi-doc-dygixywsw");
    }

    @Test
    public void testGetNameOfIntrospectionResource() {
        BObject service = TestUtils.getNewServiceObject("hello");
        BaseService baseService = new BaseService(service);
        HttpIntrospectionResource introspectionResource = new HttpIntrospectionResource(baseService, "abc");
        Assert.assertEquals(introspectionResource.getName(), "$get$openapi-doc-dygixywsw");
    }

    @Test
    public void testGetAbsoluteResourcePath() {
        BaseService baseService = new BaseService(TestUtils.getNewServiceObject("hello"));
        baseService.setBasePath("/basePath/");
        BaseResource resource = new BaseResource(TestUtils.getNewMethodType(), baseService);
        resource.setPath("/abc/{xyz}");
        baseService.setResources(Collections.singletonList(resource));
        Assert.assertEquals(resource.getAbsoluteResourcePath(), "/basePath/abc/{xyz}");
    }
}
