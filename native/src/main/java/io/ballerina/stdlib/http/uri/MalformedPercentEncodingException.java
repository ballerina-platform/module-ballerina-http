/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.uri;

/**
 * Thrown by {@link URIUtil#percentDecode(String, boolean)} for a malformed percent-escape. The message is fixed so
 * that no JDK text reaches the client.
 */
public class MalformedPercentEncodingException extends IllegalArgumentException {

    public static final String MESSAGE = "malformed percent-encoding in the request target";

    public MalformedPercentEncodingException() {
        super(MESSAGE);
    }
}
