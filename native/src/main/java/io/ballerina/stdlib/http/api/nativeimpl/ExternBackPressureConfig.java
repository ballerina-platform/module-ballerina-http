/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;

/**
 * Carries the module level back-pressure configurables down to the transport.
 */
public class ExternBackPressureConfig {

    private ExternBackPressureConfig() {
    }

    // maxBackPressureStallTime in seconds; negative excuses back-pressure indefinitely, zero excuses none.
    public static void setMaxBackPressureStallTime(BDecimal maxBackPressureStallTime) {
        Util.setMaxBackPressureStallTime(maxBackPressureStallTime.floatValue());
    }
}
