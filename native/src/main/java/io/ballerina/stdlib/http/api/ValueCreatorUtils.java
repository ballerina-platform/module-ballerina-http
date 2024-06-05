/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.mime.util.MimeUtil;

import java.net.InetSocketAddress;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;

/**
 * Utility functions to create JVM values.
 *
 * @since 1.0
 */
public class ValueCreatorUtils {

    public static BObject createRequestObject() {
        return createObjectValue(ModuleUtils.getHttpPackage(), HttpConstants.REQUEST);
    }

    public static BObject createResponseObject() {
        return createObjectValue(ModuleUtils.getHttpPackage(), HttpConstants.RESPONSE);
    }

    public static BObject createEntityObject() {
        return createObjectValue(MimeUtil.getMimePackage(), HttpConstants.ENTITY);
    }

    public static BObject createRequestCacheControlObject() {
        return createObjectValue(ModuleUtils.getHttpPackage(), HttpConstants.REQUEST_CACHE_CONTROL);
    }

    public static BObject createCallerObject(HttpCarbonMessage inboundMsg, String resourceAccessor) {
        BMap<BString, Object> remote = ValueCreatorUtils.createHTTPRecordValue(HttpConstants.REMOTE);
        BMap<BString, Object> local = ValueCreatorUtils.createHTTPRecordValue(HttpConstants.LOCAL);

        Object remoteSocketAddress = inboundMsg.getProperty(HttpConstants.REMOTE_ADDRESS);
        if (remoteSocketAddress instanceof InetSocketAddress) {
            InetSocketAddress inetSocketAddress = (InetSocketAddress) remoteSocketAddress;
            String remoteHost = inetSocketAddress.getHostString();
            long remotePort = inetSocketAddress.getPort();
            String remoteIP = inetSocketAddress.getAddress().getHostAddress();
            remote.put(HttpConstants.REMOTE_HOST_FIELD, fromString(remoteHost));
            remote.put(HttpConstants.REMOTE_PORT_FIELD, remotePort);
            remote.put(HttpConstants.REMOTE_IP_FIELD, fromString(remoteIP));
        }

        Object localSocketAddress = inboundMsg.getProperty(HttpConstants.LOCAL_ADDRESS);
        if (localSocketAddress instanceof InetSocketAddress) {
            InetSocketAddress inetSocketAddress = (InetSocketAddress) localSocketAddress;
            String localHost = inetSocketAddress.getHostString();
            long localPort = inetSocketAddress.getPort();
            String localIP = inetSocketAddress.getAddress().getHostAddress();
            local.put(HttpConstants.LOCAL_HOST_FIELD, fromString(localHost));
            local.put(HttpConstants.LOCAL_PORT_FIELD, localPort);
            local.put(HttpConstants.LOCAL_IP_FIELD, fromString(localIP));
        }
        return ValueCreator.createObjectValue(ModuleUtils.getHttpPackage(), HttpConstants.CALLER,
                remote, local, fromString((String) inboundMsg.getProperty(HttpConstants.PROTOCOL)),
                fromString(resourceAccessor));
    }

    static BObject createHeadersObject() {
        return createObjectValue(ModuleUtils.getHttpPackage(), HttpConstants.HEADERS);
    }

    static BObject createRequestContextObject() {
        return createObjectValue(ModuleUtils.getHttpPackage(), HttpConstants.REQUEST_CONTEXT);
    }
    
    /**
     * Method that creates a runtime record value using the given record type in the http package.
     *
     * @param recordTypeName name of the record type.
     * @return value of the record.
     */
    public static BMap<BString, Object> createHTTPRecordValue(String recordTypeName) {
        return ValueCreator.createRecordValue(ModuleUtils.getHttpPackage(), recordTypeName);
    }

    public static Object createStatusCodeObject(String statusCodeObjName) {
        return createObjectValue(ModuleUtils.getHttpPackage(), statusCodeObjName);
    }

    public static Object createDefaultStatusCodeObject(long statusCode) {
        return createObjectValue(ModuleUtils.getHttpPackage(), "DefaultStatus", statusCode);
    }

    /**
     * Method that creates a runtime object value using the given package id and object type name.
     *
     * @param module value creator specific for the package.
     * @param objectTypeName name of the object type.
     * @param fieldValues values to be used for fields when creating the object value instance.
     * @return value of the object.
     */
    private static BObject createObjectValue(Module module, String objectTypeName, Object... fieldValues) {
        if (fieldValues.length > 0) {
            Object[] fields = new Object[fieldValues.length * 2];
            // Adding boolean values for each arg
            for (int i = 0, j = 0; i < fieldValues.length; i++) {
                fields[j++] = fieldValues[i];
                fields[j++] = true;
            }
            return ValueCreator.createObjectValue(module, objectTypeName, fields);
        }
        return ValueCreator.createObjectValue(module, objectTypeName);
    }

    private ValueCreatorUtils() {}
}
