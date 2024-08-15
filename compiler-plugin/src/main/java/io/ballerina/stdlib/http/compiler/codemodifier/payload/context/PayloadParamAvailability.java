/*
 * Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.compiler.codemodifier.payload.context;

import io.ballerina.compiler.api.symbols.ParameterSymbol;

/**
 * {@code ParamAvailability} cache the data required during the payload param identification.
 *
 * @since 2201.5.0
 */
public class PayloadParamAvailability {

    private boolean annotatedPayloadParam = false;
    private boolean errorOccurred = false;
    private ParameterSymbol payloadParamSymbol;
    private boolean enableErrorDiagnostic = true;

    public boolean isAnnotatedPayloadParam() {
        return annotatedPayloadParam;
    }

    public void setAnnotatedPayloadParam(boolean annotatedPayloadParam) {
        this.annotatedPayloadParam = annotatedPayloadParam;
    }

    public boolean isDefaultPayloadParam() {
        return payloadParamSymbol != null;
    }


    public boolean isErrorOccurred() {
        return errorOccurred;
    }

    public void setErrorOccurred(boolean errorOccurred) {
        this.payloadParamSymbol = null;
        this.errorOccurred = errorOccurred;
    }

    public ParameterSymbol getPayloadParamSymbol() {
        return payloadParamSymbol;
    }

    public void setPayloadParamSymbol(ParameterSymbol payloadParamSymbol) {
        this.payloadParamSymbol = payloadParamSymbol;
    }

    public void setErrorDiagnostic(boolean enableErrorDiagnostic) {
        this.enableErrorDiagnostic = enableErrorDiagnostic;
    }

    public boolean isEnableErrorDiagnostic() {
        return enableErrorDiagnostic;
    }
}
