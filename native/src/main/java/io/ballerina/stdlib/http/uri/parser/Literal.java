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

package io.ballerina.stdlib.http.uri.parser;


import io.ballerina.stdlib.http.api.HttpResourceArguments;
import io.ballerina.stdlib.http.uri.URITemplateException;

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
        int fragLen = uriFragment.length();
        int tokenLen = token.length();
        int fragIdx = 0, tokenIdx = 0;

        while (fragIdx < fragLen && tokenIdx < tokenLen) {
            char fragChar = uriFragment.charAt(fragIdx);
            char tokenChar = token.charAt(tokenIdx);

            if (tokenChar == '*' && tokenIdx == tokenLen - 1) {
                return fragLen;
            }

            if (fragChar == tokenChar) {
                fragIdx++;
            } else if (fragChar == '%') {
                if (fragIdx + 2 >= fragLen) {
                    return -1;
                }
                try {
                    int decoded = Integer.parseInt(uriFragment.substring(fragIdx + 1, fragIdx + 3), 16);
                    if ((char) decoded != tokenChar) {
                        return -1;
                    }
                } catch (NumberFormatException e) {
                    return -1;
                }
                fragIdx += 3;
            } else {
                return -1;
            }
            tokenIdx++;
        }

        // Handle trailing '*' in token
        if (tokenIdx == tokenLen - 1 && token.charAt(tokenIdx) == '*') {
            return fragLen;
        }

        // Special case for root "/"
        if (uriFragment.equals("/") && token.equals("/") && !this.dataElement.hasData()) {
            return 0;
        }

        return tokenIdx == tokenLen ? fragIdx : -1;
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
