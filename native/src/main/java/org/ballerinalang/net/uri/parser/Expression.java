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


import org.ballerinalang.net.uri.URITemplateException;

import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;

/**
 * Expression represents a expression path segment in uri.
 *
 * @param <DataType> Type of data which should be stored in the node.
 * @param <InboundMsgType> Inbound message type for additional checks.
 */
public abstract class Expression<DataType, InboundMsgType> extends Node<DataType, InboundMsgType> {

    protected List<Variable> variableList = new ArrayList<Variable>(4);
    private int expressionIndex = -1;

    public Expression(DataElement<DataType, InboundMsgType> dataElement, String token, int index)
            throws URITemplateException {
        super(dataElement, token);
        this.expressionIndex = index;
        int startIndex = 0;
        for (int i = 0; i < token.length(); i++) {
            if (token.charAt(i) == ',') {
                if (startIndex == i) {
                    throw new URITemplateException("Illegal variable reference with zero length");
                } else {
                    variableList.add(new Variable(token.substring(startIndex, i)));
                    startIndex = i + 1;
                }
            } else if (i == token.length() - 1) {
                if (startIndex < token.length()) {
                    variableList.add(new Variable(token.substring(startIndex, i + 1)));
                }
            }
        }
    }

    @Override
    String getToken() {
        String str = "{";
        boolean first = true;
        for (Variable var : variableList) {
            if (!first) {
                str = str.concat(",");
            } else {
                first = false;
            }
            str = str.concat(var.getName());
        }
        str = str.concat("}");
        return str;
    }

    protected String encodeValue(String value) {
        try {
            return URLEncoder.encode(value, "UTF-8").replaceAll("\\+", "%20");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException("Error while encoding value: " + value, e);
        }
    }

    protected String decodeValue(String value) {
        try {
            return URLDecoder.decode(value.replaceAll("\\+", "%2B"), "UTF-8");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException("Error while encoding value: " + value, e);
        }
    }

    public int getExpressionIndex() {
        return expressionIndex;
    }
}
