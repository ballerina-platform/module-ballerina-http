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

package org.ballerinalang.net.transport.contractimpl.common.certificatevalidation.cache;

import org.testng.Assert;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * A unit test class for Transport module CacheController class functions.
 */
public class CacheControllerTest {

    CacheController cacheController;
    ManageableCache manageableCache, cache;
    CacheManager cacheManager;

    @BeforeMethod
    public void initializeCacheController() {
        manageableCache = mock(ManageableCache.class);
        when(manageableCache.getCacheSize()).thenReturn(25);
        cache = mock(ManageableCache.class);
        cacheManager = new CacheManager(cache, 10, 5);
        cacheController = new CacheController(manageableCache, cacheManager);
    }

    @Test
    public void testStopCacheManger() {
        Assert.assertTrue(cacheController.stopCacheManager());
        Assert.assertFalse(cacheController.stopCacheManager());
    }

    @Test
    public void testWakeUpCacheManager() {
        Assert.assertTrue(cacheController.wakeUpCacheManager());
        cacheManager.stop();
        Assert.assertTrue(cacheController.wakeUpCacheManager());
    }

    @Test
    public void testChangeCacheManagerDelayMins() {
        Assert.assertTrue(cacheController.changeCacheManagerDelayMins(10));
        Assert.assertEquals(cacheManager.getDelay(), 10);
    }

    @Test (expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Delay time should should be between 1 and 1440 minutes")
    public void testChangeCacheManagerDelayMinsWithInvalidArgument1() {
        cacheController.changeCacheManagerDelayMins(0);
    }

    @Test (expectedExceptions = IllegalArgumentException.class,
            expectedExceptionsMessageRegExp = "Delay time should should be between 1 and 1440 minutes")
    public void testChangeCacheManagerDelayMinsWithInvalidArgument2() {
        cacheController.changeCacheManagerDelayMins(1500);
    }

    @Test
    public void testIsCacheManagerRunning() {
        Assert.assertTrue(cacheController.isCacheManagerRunning());
        cacheManager.stop();
        Assert.assertFalse(cacheController.isCacheManagerRunning());
    }

    @Test
    public void testGetCacheSize() {
        Assert.assertEquals(cacheController.getCacheSize(), 25);
    }

    @Test
    public void testGetCacheManagerDelayMins() {
        Assert.assertEquals(cacheController.getCacheManagerDelayMins(), 5);
        cacheManager.changeDelay(10);
        Assert.assertEquals(cacheController.getCacheManagerDelayMins(), 10);
    }

}
