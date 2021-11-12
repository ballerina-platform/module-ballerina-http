package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.URITemplate;
import io.ballerina.stdlib.http.uri.URITemplateException;

import java.util.List;

/**
 * Interface for HTTP Service classes.
 */
public interface Service {
    BMap<BString, Object> getCompressionConfig();

    String getChunkingConfig();

    String getMediaTypeSubtypePrefix();

    URITemplate<Resource, HttpCarbonMessage> getUriTemplate() throws URITemplateException;

    String getBasePath();

    List<String> getAllAllowedMethods();

    String getIntrospectionResourcePathHeaderValue();
}
