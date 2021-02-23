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

package org.ballerinalang.net.uri.nativeimpl;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.net.http.HttpUtil;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;

/**
 * Decodes a given URL.
 *
 * @since 2.0.0
 */
public class Decode {

    public static Object decode(BString url, BString charset) {
        try {
            return StringUtils.fromString(URLDecoder.decode(url.getValue(), charset.getValue()));
        } catch (UnsupportedEncodingException e) {
            return HttpUtil.createHttpError("Error occurred while decoding the URL. " + e.getMessage());
        }
    }
}
