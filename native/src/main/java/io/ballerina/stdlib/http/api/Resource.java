package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;

import java.util.List;

/**
 * Interface for HTTP Resource classes.
 */
public interface Resource {

    List<String> getMethods();

    ParamHandler getParamHandler();

    ResourceMethodType getBalResource();

    boolean isTreatNilableAsOptional();

    String getWildcardToken();

    Service getParentService();

    List<String> getConsumes();

    List<String> getProduces();

    List<String> getProducesSubTypes();

    String getName();

    Object getCorsHeaders();
}
