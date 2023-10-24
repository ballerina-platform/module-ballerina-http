/*
*  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
*
*  WSO2 Inc. licenses this file to you under the Apache License,
*  Version 2.0 (the "License"); you may not use this file except
*  in compliance with the License.
*  You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing,
*  software distributed under the License is distributed on an
*  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
*  KIND, either express or implied.  See the License for the
*  specific language governing permissions and limitations
*  under the License.
*/

package io.ballerina.stdlib.http.uri;

import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpResource;
import io.ballerina.stdlib.http.api.HttpService;
import io.ballerina.stdlib.http.api.InterceptorResource;
import io.ballerina.stdlib.http.api.InterceptorService;
import io.ballerina.stdlib.http.api.Resource;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Utilities related to dispatcher processing.
 */
public final class DispatcherUtil {

    private DispatcherUtil() {}

    private static String[] allMethods = new String[]{HttpConstants.HTTP_METHOD_GET, HttpConstants.HTTP_METHOD_HEAD
            , HttpConstants.HTTP_METHOD_POST, HttpConstants.HTTP_METHOD_DELETE, HttpConstants.HTTP_METHOD_PATCH
            , HttpConstants.HTTP_METHOD_PUT, HttpConstants.HTTP_METHOD_OPTIONS};

    public static boolean isMatchingMethodExist(Resource resourceInfo, String method) {
        if (resourceInfo.getMethods() == null) {
            return false;
        }
        return resourceInfo.getMethods().contains(method);
    }

    public static String concatValues(List<String> stringValues, boolean spaceSeparated) {
        StringBuilder builder = new StringBuilder();
        String separator = spaceSeparated ? " " : ", ";
        for (int x = 0; x < stringValues.size(); ++x) {
            builder.append(stringValues.get(x));
            if (x != stringValues.size() - 1) {
                builder.append(separator);
            }
        }
        return builder.toString();
    }

    public static List<String> validateAllowMethods(List<String> cachedMethods) {
        //cachedMethods cannot be null here.
        if (cachedMethods.isEmpty()) {
            return cachedMethods;
        }
        cachedMethods.add(HttpConstants.HTTP_METHOD_OPTIONS);
        cachedMethods = cachedMethods.stream().distinct().collect(Collectors.toList());
        return cachedMethods;
    }

    public static List<String> addAllMethods() {
        return Arrays.stream(allMethods).collect(Collectors.toList());
    }

    public static List<String> getAllResourceMethods(HttpService service) {
        List<String> cachedMethods = new ArrayList<>();
        for (HttpResource resource : service.getResources()) {
            if (resource.getMethods() == null) {
                cachedMethods.addAll(DispatcherUtil.addAllMethods());
                break;
            }
            cachedMethods.addAll(resource.getMethods());
        }
        return validateAllowMethods(cachedMethods);
    }

    public static List<String> getInterceptorResourceMethods(InterceptorService httpInterceptorService) {
        List<String> cachedMethods = new ArrayList<>();
        InterceptorResource resource = httpInterceptorService.getResource();
        if (resource.getMethods() == null) {
            cachedMethods.addAll(DispatcherUtil.addAllMethods());
        } else {
            cachedMethods.addAll(resource.getMethods());
        }
        return validateAllowMethods(cachedMethods);
    }
}
