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
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;

/**
 * {@code {@link AllHeaderParams }} holds all the header parameters in the resource signature.
 *
 * @since sl-alpha3
 */
public class AllHeaderParams implements Parameter {

    private final List<HeaderParam> allHeaderParams = new ArrayList<>();

    @Override
    public String getTypeName() {
        return HttpConstants.HEADER_PARAM;
    }

    public void add(HeaderParam headerParam) {
        allHeaderParams.add(headerParam);
    }

    boolean isNotEmpty() {
        return !allHeaderParams.isEmpty();
    }

    public List<HeaderParam> getAllHeaderParams() {
        return this.allHeaderParams;
    }

    public HeaderParam get(String token) {
        for (HeaderParam headerParam : allHeaderParams) {
            if (token.equals(headerParam.getToken())) {
                return headerParam;
            }
        }
        return null;
    }

    public void populateFeed(HttpCarbonMessage httpCarbonMessage, Object[] paramFeed, boolean treatNilableAsOptional) {
        HttpHeaders httpHeaders = httpCarbonMessage.getHeaders();
        for (HeaderParam headerParam : this.getAllHeaderParams()) {
            String token = headerParam.getHeaderName();
            int index = headerParam.getIndex();
            List<String> headerValues = httpHeaders.getAll(token);
            if (headerValues.isEmpty()) {
                if (headerParam.isNilable() && treatNilableAsOptional) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                    throw new BallerinaConnectorException("no header value found for '" + token + "'");
                }
            }
            if (headerValues.size() == 1 && headerValues.get(0).isEmpty()) {
                if (headerParam.isNilable()) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                    throw new BallerinaConnectorException("no header value found for '" + token + "'");
                }
            }
            if (headerParam.getTypeTag() == ARRAY_TAG) {
                BArray bArray = StringUtils.fromStringArray(headerValues.toArray(new String[0]));
                if (headerParam.isReadonly()) {
                    bArray.freezeDirect();
                }
                paramFeed[index++] = bArray;
            } else {
                paramFeed[index++] = StringUtils.fromString(headerValues.get(0));
            }
            paramFeed[index] = true;
        }
    }

}
