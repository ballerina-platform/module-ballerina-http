/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.compiler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Represents links related data to a specific service.
 */
public class LinksMetaData {
    Map<String, List<LinkedResource>> linkedResourcesMap;
    List<Map<String, LinkedToResource>> linkedToResourceMaps;
    boolean nameRefObjsAvailable;

    public LinksMetaData() {
        this.linkedResourcesMap = new HashMap<>();
        this.linkedToResourceMaps = new ArrayList<>();
        this.nameRefObjsAvailable = false;
    }

    public Map<String, List<LinkedResource>> getLinkedResourcesMap() {
        return linkedResourcesMap;
    }

    public List<Map<String, LinkedToResource>> getLinkedToResourceMaps() {
        return linkedToResourceMaps;
    }

    public boolean hasNameReferenceObjects() {
        return nameRefObjsAvailable;
    }

    public void markNameRefObjsAvailable() {
        this.nameRefObjsAvailable = true;
    }

    public boolean isValidLinkedResource(String resourceName, String path) {
        if (linkedResourcesMap.containsKey(resourceName)) {
            List<LinkedResource> linkedResources = linkedResourcesMap.get(resourceName);
            for (LinkedResource linkedResource : linkedResources) {
                return linkedResource.getPath().equals(path);
            }
        }
        return true;
    }

    public void addLinkedResource(String resourceName, String path, String method) {
        if (linkedResourcesMap.containsKey(resourceName)) {
            List<LinkedResource> linkedResources = linkedResourcesMap.get(resourceName);
            linkedResources.add(new LinkedResource(path, method));
        } else {
            List<LinkedResource> linkedResources = new ArrayList<>();
            linkedResources.add(new LinkedResource(path, method));
            linkedResourcesMap.put(resourceName, linkedResources);
        }
    }

    public void addLinkedToResourceMap(Map<String, LinkedToResource> linkedToResourceMap) {
        this.linkedToResourceMaps.add(linkedToResourceMap);
    }
}
