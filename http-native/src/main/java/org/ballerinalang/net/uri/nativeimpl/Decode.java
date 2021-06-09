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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.net.uri.nativeimpl;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.net.http.HttpUtil;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;

import static org.ballerinalang.net.http.HttpErrorType.GENERIC_CLIENT_ERROR;

/**
 * Decode a given path against a given charset.
 *
 * @since SL beta2
 */
public class Decode {

    public static Object decode(BString str, BString charset) {
        try {
            String decode = URLDecoder.decode(str.getValue().replaceAll("\\+", "%2B"), charset.getValue());
            return StringUtils.fromString(decode);
        } catch (UnsupportedEncodingException e) {
            return HttpUtil.createHttpError("error occurred while decoding. " + e.getMessage(), GENERIC_CLIENT_ERROR);
        }
    }

    private Decode() {
    }
}
