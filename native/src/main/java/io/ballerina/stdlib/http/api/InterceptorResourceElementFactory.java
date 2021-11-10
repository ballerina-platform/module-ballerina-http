package io.ballerina.stdlib.http.api;

import io.ballerina.stdlib.http.uri.parser.DataElementFactory;

/**
 * Factory to create {@link InterceptorResourceDataElement}.
 */
public class InterceptorResourceElementFactory implements DataElementFactory<InterceptorResourceDataElement> {

    @Override
    public InterceptorResourceDataElement createDataElement() {
        return new InterceptorResourceDataElement();
    }
}
