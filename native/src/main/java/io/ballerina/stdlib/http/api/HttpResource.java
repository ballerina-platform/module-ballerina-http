package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;

import java.util.List;

/**
 * Interface for HTTP Resource classes.
 */
public interface HttpResource {

    public List<String> getMethods();

    ParamHandler getParamHandler();

    ResourceMethodType getBalResource();

    boolean isTreatNilableAsOptional();

    String getWildcardToken();

    HttpService getParentService();
}
