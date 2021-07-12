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

import java.util.HashMap;
import java.util.Map;

/**
 * SimpleStringExpression represents path segments that have single path param.
 * ex - /{foo}/
 *
 * @param <DataType> Type of data which should be stored in the node.
 * @param <InboundMsgType> Inbound message type for additional checks.
 */
public class SimpleStringExpression<DataType, InboundMsgType> extends Expression<DataType, InboundMsgType> {

    private static final char[] RESERVED = new char[]{
            ':', '/', '?', '#', '[', ']', '@', '!', '$', '&', '\'', '(', ')', '*', '+', ',', ';', '='
    };

    SimpleStringExpression(DataElement<DataType, InboundMsgType> dataElement, String token, int index)
            throws URITemplateException {
        super(dataElement, token, index);
    }

    @Override
    String expand(Map<String, String> variables) {
        boolean emptyString = false;
        StringBuilder buffer = new StringBuilder();
        for (Variable var : variableList) {
            String name = var.getName();
            if (!variables.containsKey(name)) {
                continue;
            }
            if (buffer.length() > 0) {
                buffer.append(getSeparator());
            }
            String value = var.modify(variables.get(name));
            if ("".equals(value)) {
                emptyString = true;
            }
            buffer.append(encodeValue(value));
        }

        if (buffer.length() == 0 && !emptyString) {
            return null;
        }
        return buffer.toString();
    }

    @Override
    int match(String uriFragment, HttpResourceArguments variables) {
        int length = uriFragment.length();
        for (int i = 0; i < length; i++) {
            char ch = uriFragment.charAt(i);
            if (isEndCharacter(ch)) {
                if (ch == getSeparator() && variableList.size() > 0) {
                    continue;
                }

                if (!setVariables(uriFragment.substring(0, i), variables)) {
                    return -1;
                }
                return i;
            } else if (i == length - 1) {
                if (!setVariables(uriFragment, variables)) {
                    return -1;
                }
                return length;
            }
        }
        return 0;
    }

    @Override
    char getFirstCharacter() {
        return '\u0001';
    }

    protected boolean isEndCharacter(Character endCharacter) {
        return endCharacter == '/';
    }

    private char getSeparator() {
        return ',';
    }

    boolean setVariables(String expressionValue, HttpResourceArguments variables) {
        String finalValue = decodeValue(expressionValue);
        for (Variable var : variableList) {
            String name = var.getName();
            Map<Integer, String> indexValueMap;
            if (variables.getMap().containsKey(name)) {
                indexValueMap = variables.getMap().get(name);
            } else {
                indexValueMap = new HashMap<>();
                variables.getMap().put(name, indexValueMap);
            }
            if (var.checkModifier(finalValue)) {
                indexValueMap.put(getExpressionIndex(), finalValue);
            } else {
                return false;
            }
        }
        return true;
    }

    protected boolean isReserved(char ch) {
        for (char reservedChar : RESERVED) {
            if (ch == reservedChar) {
                return true;
            }
        }
        return false;
    }
}
