/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.types.FunctionType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MethodType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.Parameter;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import org.mockito.Mockito;

/**
 * A test utils for http unit test classes.
 */
public final class TestUtils {

    private TestUtils() {}

    public static final int SOCKET_SERVER_PORT = 8001;

    static BObject getNewServiceObject(String name) {
        BObject serviceObject = Mockito.mock(BObject.class);
        Mockito.when(serviceObject.getType()).thenReturn(TypeCreator.createObjectType(name + "$$service$",
                ModuleUtils.getHttpPackage(), 0));
        return serviceObject;
    }

    static MethodType getNewMethodType() {
        return new MethodType() {

            @Override
            public String getAnnotationKey() {
                return null;
            }

            @Override
            public Object getAnnotation(BString bString) {
                return null;
            }

            @Override
            public Object getAnnotation(BString bString, BString bString1) {
                return null;
            }

            @Override
            public BMap<BString, Object> getAnnotations() {
                return null;
            };

            @Override
            public Type getReturnType() {
                return null;
            }

            @Override
            public <V> V getZeroValue() {
                return null;
            }

            @Override
            public <V> V getEmptyValue() {
                return null;
            }

            @Override
            public int getTag() {
                return 0;
            }

            @Override
            public boolean isNilable() {
                return false;
            }

            @Override
            public String getName() {
                return null;
            }

            @Override
            public String getQualifiedName() {
                return null;
            }

            @Override
            public Module getPackage() {
                return null;
            }

            @Override
            public boolean isPublic() {
                return false;
            }

            @Override
            public boolean isNative() {
                return false;
            }

            @Override
            public boolean isAnydata() {
                return false;
            }

            @Override
            public boolean isPureType() {
                return false;
            }

            @Override
            public boolean isReadOnly() {
                return false;
            }

            @Override
            public long getFlags() {
                return 0;
            }

            @Override
            public Type getImmutableType() {
                return null;
            }

            @Override
            public void setImmutableType(IntersectionType intersectionType) {

            }

            @Override
            public Module getPkg() {
                return null;
            }

            @Override
            public Type getReturnParameterType() {
                return null;
            }

            @Override
            public Type getRestType() {
                return null;
            }

            @Override
            public Parameter[] getParameters() {
                return new Parameter[0];
            }

            @Override
            public ObjectType getParentObjectType() {
                return null;
            }

            @Override
            public FunctionType getType() {
                return null;
            }

            @Override
            public boolean isIsolated() {
                return false;
            }
        };
    }
}
