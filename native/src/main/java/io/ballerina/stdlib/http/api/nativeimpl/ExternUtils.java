// Copyright (c) 2022 WSO2 Org. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 Org. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;
import io.netty.handler.codec.http.HttpResponseStatus;

/**
 * Contains external utility functions.
 */
public class ExternUtils {

    /**
     * Provides the relevant reason phrase for a given status code.
     *
     * @param statusCode Status code value
     * @return Returns the reason phrase of the status code
     */
    public static BString getReasonFromStatusCode(Long statusCode) {
        String reasonPhrase;
        // 451 and 508 are not available in `HttpResponseStatus`.
        if (statusCode.intValue() == 451) {
            reasonPhrase = "Unavailable For Legal Reasons";
        } else if (statusCode.intValue() == 508) {
            reasonPhrase = "Loop Detected";
        } else {
            reasonPhrase = HttpResponseStatus.valueOf(statusCode.intValue()).reasonPhrase();
            if (reasonPhrase.contains("Unknown Status")) {
                reasonPhrase = HttpResponseStatus.valueOf(500).reasonPhrase();
            }
        }
        return StringUtils.fromString(reasonPhrase);
    }

}
