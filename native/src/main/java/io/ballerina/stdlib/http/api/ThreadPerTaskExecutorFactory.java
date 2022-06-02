/*
 *  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.api;

import io.netty.util.concurrent.DefaultThreadFactory;
import io.netty.util.concurrent.ThreadPerTaskExecutor;

import static io.ballerina.stdlib.http.transport.contract.Constants.BOSS_GROUP_THREAD_POOL_NAME;
import static io.ballerina.stdlib.http.transport.contract.Constants.CLIENT_GROUP_THREAD_POOL_NAME;
import static io.ballerina.stdlib.http.transport.contract.Constants.WORKER_GROUP_THREAD_POOL_NAME;

/**
 * This class is to provide a static instance of the ThreadPerTaskExecutor which will be shared when creating
 * EventLoopGroup in the DefaultHttpWsConnectorFactory.
 */
public class ThreadPerTaskExecutorFactory {
    private static final ThreadPerTaskExecutor bossGroupExecutor = new ThreadPerTaskExecutor(
            new DefaultThreadFactory(BOSS_GROUP_THREAD_POOL_NAME));
    private static final ThreadPerTaskExecutor workerGroupExecutor = new ThreadPerTaskExecutor(
            new DefaultThreadFactory(WORKER_GROUP_THREAD_POOL_NAME));
    private static final ThreadPerTaskExecutor clientGroupExecutor = new ThreadPerTaskExecutor(
            new DefaultThreadFactory(CLIENT_GROUP_THREAD_POOL_NAME));

    public static ThreadPerTaskExecutor getBossGroupThreadPerTaskExecutor() {
        return bossGroupExecutor;
    }

    public static ThreadPerTaskExecutor getWorkerGroupThreadPerTaskExecutor() {
        return workerGroupExecutor;
    }

    public static ThreadPerTaskExecutor getClientGroupThreadPerTaskExecutor() {
        return clientGroupExecutor;
    }

    private ThreadPerTaskExecutorFactory() {
    }
}
