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

package io.ballerina.stdlib.http.transport.internal;

import io.ballerina.stdlib.http.transport.contract.config.ListenerConfiguration;
import io.netty.channel.EventLoopGroup;
import org.osgi.framework.BundleContext;
import org.testng.Assert;
import org.testng.annotations.Test;

import static org.mockito.Mockito.mock;

/**
 * A unit test class for Transport module HttpTransportContextHolder class functions.
 */
public class HttpTransportContextHolderTest {

    @Test
    public void testGetAndSetBossGroup() {
        EventLoopGroup bossGroup = mock(EventLoopGroup.class);
        HttpTransportContextHolder httpTransportContextHolder = HttpTransportContextHolder.getInstance();
        httpTransportContextHolder.setBossGroup(bossGroup);
        EventLoopGroup returnVal = httpTransportContextHolder.getBossGroup();
        Assert.assertEquals(returnVal, bossGroup);
    }

    @Test
    public void testGetAndSetWorkerGroup() {
        EventLoopGroup workerGroup = mock(EventLoopGroup.class);
        HttpTransportContextHolder httpTransportContextHolder = HttpTransportContextHolder.getInstance();
        httpTransportContextHolder.setWorkerGroup(workerGroup);
        EventLoopGroup returnVal = httpTransportContextHolder.getWorkerGroup();
        Assert.assertEquals(returnVal, workerGroup);
    }

    @Test
    public void testGetAndSetListenerConfiguration() {
        ListenerConfiguration config = new ListenerConfiguration();
        String id = "id";
        HttpTransportContextHolder httpTransportContextHolder = HttpTransportContextHolder.getInstance();
        httpTransportContextHolder.setListenerConfiguration(id, config);
        ListenerConfiguration returnVal = httpTransportContextHolder.getListenerConfiguration(id);
        Assert.assertEquals(returnVal, config);
    }

    @Test
    public void testGetAndSetBundleContext() {
        BundleContext bundleContext = mock(BundleContext.class);
        HttpTransportContextHolder httpTransportContextHolder = HttpTransportContextHolder.getInstance();
        httpTransportContextHolder.setBundleContext(bundleContext);
        BundleContext returnVal = httpTransportContextHolder.getBundleContext();
        Assert.assertEquals(returnVal, bundleContext);
    }

}
