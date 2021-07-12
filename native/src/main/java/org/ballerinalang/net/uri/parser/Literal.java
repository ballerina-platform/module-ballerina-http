/*
*  Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.uri.parser;


import org.ballerinalang.net.http.HttpResourceArguments;
import org.ballerinalang.net.uri.URITemplateException;

import java.util.Map;

/**
 * Literal represents literal path segments in the uri-template.
 *
 * @param <DataType> Type of data which should be stored in the node.
 * @param <InboundMsgType> Inbound message type for additional checks.
 */
public class Literal<DataType, InboundMsgType> extends Node<DataType, InboundMsgType> {

    private int tokenLength;

    public Literal(DataElement<DataType, InboundMsgType> dataElement, String token) throws URITemplateException {
        super(dataElement, token);
        tokenLength = token.length();
        if (tokenLength == 0) {
            throw new URITemplateException("Invalid literal token with zero length");
        }
    }

    @Override
    String expand(Map<String, String> variables) {
        return token;
    }

    @Override
    int match(String uriFragment, HttpResourceArguments variables) {
        if (!token.endsWith("*")) {
            if (uriFragment.length() < tokenLength) {
                return -1;
            }
            for (int i = 0; i < tokenLength; i++) {
                if (token.charAt(i) != uriFragment.charAt(i)) {
                    if (token.charAt(i) == '*' && i == token.length() - 1) {
                        return uriFragment.length();
                    }
                    return -1;
                }
            }
            //special case request urls which contains only the root("/") to be dispatched to default resource("/*").
            if (uriFragment.equals("/") && uriFragment.equals(token) && !this.dataElement.hasData()) {
                return 0;
            }
            return tokenLength;
        } else {
            if (uriFragment.length() < tokenLength - 1) {
                return -1;
            }
            for (int i = 0; i < tokenLength - 1; i++) {
                if (token.charAt(i) != uriFragment.charAt(i)) {
                    if (i == token.length() - 1) {
                        return uriFragment.length();
                    }
                    return -1;
                }
            }
            return uriFragment.length();
        }
    }

    @Override
    String getToken() {
        return token;
    }

    @Override
    char getFirstCharacter() {
        return token.charAt(0);
    }
}
