/*
 *  Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.testutils.nativeimpl;

import io.ballerina.runtime.api.values.BObject;


/**
 * External function for Process.stop.
 *
 * @since 2.16.0
 */
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

public class Stop {

    private Stop() {}

    private static final int TIMEOUT_SECONDS = 5;

    public static Object stop(BObject objVal) {
        Process process = OSUtils.processFromObject(objVal);

        if (!process.isAlive()) {
            return true;
        }

        List<ProcessHandle> descendants = process.descendants()
                .collect(Collectors.toList());
        descendants.forEach(ProcessHandle::destroy);
        process.destroy();
        try {
            boolean terminated = process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);
            if (!terminated) {
                descendants.forEach(ProcessHandle::destroyForcibly);
                process.destroyForcibly();
                process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            descendants.forEach(ProcessHandle::destroyForcibly);
            process.destroyForcibly();
        }
        return !process.isAlive();
    }
}
