/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

import io.ballerina.stdlib.http.transport.contract.config.ProxyServerConfiguration;
import org.testng.Assert;
import org.testng.annotations.Test;

public class ProxyEnvVarTest {

    @Test
    public void testShouldBypassProxy() {
        // Exact match
        Assert.assertTrue(HttpUtil.shouldBypassProxy("localhost", "localhost"));
        Assert.assertTrue(HttpUtil.shouldBypassProxy("example.com", "example.com"));
        
        // Exact match case-insensitivity
        Assert.assertTrue(HttpUtil.shouldBypassProxy("Example.Com", "example.com"));
        Assert.assertTrue(HttpUtil.shouldBypassProxy("example.com", "EXAMPLE.COM"));

        // Wildcard
        Assert.assertTrue(HttpUtil.shouldBypassProxy("example.com", "*"));

        // Suffix match
        Assert.assertTrue(HttpUtil.shouldBypassProxy("sub.example.com", "example.com"));
        Assert.assertTrue(HttpUtil.shouldBypassProxy("sub.example.com", ".example.com"));
        Assert.assertTrue(HttpUtil.shouldBypassProxy("example.com", ".example.com"));

        // No match
        Assert.assertFalse(HttpUtil.shouldBypassProxy("another-example.com", "example.com"));
        Assert.assertFalse(HttpUtil.shouldBypassProxy("example.org", "example.com"));

        // List match
        Assert.assertTrue(HttpUtil.shouldBypassProxy("localhost", "example.com, localhost, google.com"));
        Assert.assertTrue(HttpUtil.shouldBypassProxy("sub.example.com", "example.com, localhost"));
    }

    @Test
    public void testParseProxyUrl() {
        // Without scheme
        ProxyServerConfiguration config1 = HttpUtil.parseProxyUrl("proxy.example.com:8080");
        Assert.assertEquals(config1.getProxyHost(), "proxy.example.com");
        Assert.assertEquals(config1.getProxyPort(), 8080);
        Assert.assertNull(config1.getProxyUsername());
        Assert.assertNull(config1.getProxyPassword());

        // With scheme (http)
        ProxyServerConfiguration config2 = HttpUtil.parseProxyUrl("http://proxy.example.com:8080");
        Assert.assertEquals(config2.getProxyHost(), "proxy.example.com");
        Assert.assertEquals(config2.getProxyPort(), 8080);

        // With credentials
        ProxyServerConfiguration config3 = HttpUtil.parseProxyUrl("http://user:pass@proxy.example.com:8080");
        Assert.assertEquals(config3.getProxyHost(), "proxy.example.com");
        Assert.assertEquals(config3.getProxyPort(), 8080);
        Assert.assertEquals(config3.getProxyUsername(), "user");
        Assert.assertEquals(config3.getProxyPassword(), "pass");

        // Without port
        ProxyServerConfiguration config4 = HttpUtil.parseProxyUrl("http://proxy.example.com");
        Assert.assertEquals(config4.getProxyHost(), "proxy.example.com");
        Assert.assertEquals(config4.getProxyPort(), 80);

        // HTTPS scheme without port
        ProxyServerConfiguration config5 = HttpUtil.parseProxyUrl("https://proxy.example.com");
        Assert.assertEquals(config5.getProxyHost(), "proxy.example.com");
        Assert.assertEquals(config5.getProxyPort(), 443);
    }
}
