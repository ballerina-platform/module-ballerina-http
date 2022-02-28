package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.types.RemoteMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpConstants.COLON;
import static io.ballerina.stdlib.http.api.HttpConstants.PROTOCOL_HTTP;

/**
 * This class holds the response interceptor remote signature parameters.
 */
public class RemoteMethodParamHandler {

    private final Type[] paramTypes;
    private RemoteMethodType remoteMethod;
    private List<Parameter> otherParamList = new ArrayList<>();
    private NonRecurringParam responseParam = null;
    private NonRecurringParam requestContextParam = null;
    private NonRecurringParam interceptorErrorParam = null;
    private NonRecurringParam callerParam = null;

    private static final String RES_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.RESPONSE;
    private static final String REQUEST_CONTEXT_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.REQUEST_CONTEXT;
    private static final String CALLER_TYPE = PROTOCOL_HTTP + COLON + HttpConstants.CALLER;

    public RemoteMethodParamHandler(RemoteMethodType remoteMethod) {
        this.remoteMethod = remoteMethod;
        this.paramTypes = remoteMethod.getParameterTypes();
        validateSignatureParams();
    }

    private void validateSignatureParams() {
        for (int index = 0; index < paramTypes.length; index++) {
            Type parameterType = remoteMethod.getParameterTypes()[index];
            String typeName = parameterType.toString();
            switch (typeName) {
                case REQUEST_CONTEXT_TYPE:
                    if (this.requestContextParam == null) {
                        this.requestContextParam = new NonRecurringParam(index, HttpConstants.REQUEST_CONTEXT);
                        getOtherParamList().add(this.requestContextParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + REQUEST_CONTEXT_TYPE
                                + "' parameter");
                    }
                    break;
                case HttpConstants.STRUCT_GENERIC_ERROR:
                    if (this.interceptorErrorParam == null) {
                        this.interceptorErrorParam = new NonRecurringParam(index,
                                HttpConstants.STRUCT_GENERIC_ERROR);
                        getOtherParamList().add(this.interceptorErrorParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" +
                                HttpConstants.STRUCT_GENERIC_ERROR + "' parameter");
                    }
                    break;
                case RES_TYPE:
                    if (this.responseParam == null) {
                        this.responseParam = new NonRecurringParam(index, HttpConstants.RESPONSE);
                        getOtherParamList().add(this.responseParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + RES_TYPE + "' parameter");
                    }
                    break;
                case CALLER_TYPE:
                    if (this.callerParam == null) {
                        this.callerParam = new NonRecurringParam(index, HttpConstants.CALLER);
                        getOtherParamList().add(this.callerParam);
                    } else {
                        throw HttpUtil.createHttpError("invalid multiple '" + CALLER_TYPE + "' parameter");
                    }
                    break;
                default:
                    throw  HttpUtil.createHttpError("unsupported signature parameter type : '" +
                            typeName + "'");
            }
        }
    }

    public int getParamCount() {
        return this.paramTypes.length;
    }

    public List<Parameter> getOtherParamList() {
        return this.otherParamList;
    }
}
