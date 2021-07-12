/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.transport.message;

/**
 * Allows listeners to register and get notified.
 */
public interface FullHttpMessageFuture {

    /**
     * Set listener interested for complete {@link HttpCarbonMessage}.
     *
     * @param listener for message
     */
    void addListener(FullHttpMessageListener listener);

    /**
     * Remove listener from the future.
     */
    void removeListener();

    /**
     * Notify when the complete content is added to {@link HttpCarbonMessage}.
     */
    void notifySuccess();

    /**
     * Notify the error occurs during the accumulation.
     *
     * @param error of the message
     */
    void notifyFailure(Exception error);
}
