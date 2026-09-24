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

package io.ballerina.stdlib.http.transport.contractimpl.sender;

import io.ballerina.stdlib.http.transport.contractimpl.common.EntityBodySizeValidator;
import io.netty.channel.ChannelHandlerContext;

/**
 * Responsible for validating response entity body size before sending it to the application. If the validation fails,
 * throws an exception to be handled by the targetHandler for downstream notification through respective response
 * state.
 */
public class ResponseEntityBodySizeValidator extends EntityBodySizeValidator {

    public ResponseEntityBodySizeValidator(long maxEntityBodySize) {
        super(maxEntityBodySize);
    }

    @Override
    protected void onLimitExceeded(ChannelHandlerContext ctx) {
        throw new IllegalStateException("Response max entity body size exceeds: Entity body is larger than "
                                           + this.maxEntityBodySize + " bytes. ");
    }
}
