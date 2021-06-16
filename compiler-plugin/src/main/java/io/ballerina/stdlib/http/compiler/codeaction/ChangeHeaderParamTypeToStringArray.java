package io.ballerina.stdlib.http.compiler.codeaction;

/**
 * Code action to change header parameter's type to string[].
 */
public class ChangeHeaderParamTypeToStringArray extends ChangeHeaderParamType {

    @Override
    protected String headerParamType() {
        return "string[]";
    }

    @Override
    public String name() {
        return "CHANGE_HEADER_PARAM_STRING_ARRAY";
    }
}
