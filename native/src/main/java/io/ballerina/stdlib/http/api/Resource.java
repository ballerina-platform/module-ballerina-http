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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;

import java.util.List;

/**
 * Represents the interface for HTTP Resource classes.
 */
public interface Resource {
    /**
     * Returns the HTTP methods in the resource.
     *
     * @return the list of HTTP methods
     */
    List<String> getMethods();

    /**
     * Returns the Parameter Handler from the resource.
     *
     * @return the Parameter Handler
     */
    ParamHandler getParamHandler();

    /**
     * Returns the Ballerina resource method type.
     *
     * @return the resource method type
     */
    ResourceMethodType getBalResource();

    /**
     * Returns whether the nilable query parameters are considered as optional or not.
     */
    boolean isTreatNilableAsOptional();

    /**
     * Returns the wildcard token in the resource path.
     *
     * @return the wildcard token string
     */
    String getWildcardToken();

    /**
     * Returns the parent service of the resource.
     *
     * @return the HTTP parent service
     */
    Service getParentService();

    /**
     * Returns the consumes fields from the resource config annotation.
     *
     * @return the list of consumes fields
     */
    List<String> getConsumes();

    /**
     * Returns the produces fields from the resource config annotation.
     *
     * @return the list of produces fields
     */
    List<String> getProduces();

    /**
     * Returns the sub-attribute values of produces field.
     *
     * @return the sub-attribute values
     */
    List<String> getProducesSubTypes();

    /**
     * Returns the resource name with the resource method.
     *
     * @return the resource name with resource method
     */
    String getName();

    /**
     * Returns the CORS headers from resource config annotation.
     *
     * @return the CORS header object
     */
    Object getCorsHeaders();
}
