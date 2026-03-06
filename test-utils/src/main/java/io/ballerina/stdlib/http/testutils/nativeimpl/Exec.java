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

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Extern function exec.
 *
 * @since 2.16.0
 */
public class Exec {
    
    public static Object exec(BString command, BMap<BString, BString> env, Object dir, BString[] args) {
        List<String> commandList = new ArrayList<>();
        commandList.add(command.getValue());
        commandList.addAll(Arrays.stream(args).map(BString::getValue).collect(Collectors.toList()));
        ProcessBuilder pb = new ProcessBuilder(commandList);
        if (dir != null) {
            pb.directory(new File(((BString) dir).getValue()));
        }
        if (env != null) {
            Map<String, String> pbEnv = pb.environment();
            env.entrySet().forEach(entry -> pbEnv.put(entry.getKey().getValue(), entry.getValue().getValue()));
        }
        try {
            return OSUtils.getProcessObject(pb.start());
        } catch (IOException e) {
            return OSUtils.getBallerinaError(OSConstants.PROCESS_EXEC_ERROR, e);
        }
    }
}
