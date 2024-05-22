/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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
package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.values.BError;

/**
 * Status code binding exception to indicate that the status code data-binding has failed.
 *
 * @since 2.11.1
 */
public class StatusCodeBindingException extends RuntimeException {

    final String errorType;
    final BError cause;

    public StatusCodeBindingException(String errorType, String message) {
        super(message);
        this.errorType = errorType;
        this.cause = null;
    }

    public StatusCodeBindingException(String errorType, String message, BError cause) {
        super(message);
        this.errorType = errorType;
        this.cause = cause;
    }

    public String getErrorType() {
        return errorType;
    }

    public BError getBError() {
        return cause;
    }
}
