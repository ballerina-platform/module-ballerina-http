package io.ballerina.stdlib.http.compiler.codeaction;

/**
 * Change header paramer type to string code action.
 */
public class ChangeHeaderParamTypeToString extends ChangeHeaderParamType{

    @Override
    protected String headerParamType() {
        return "string";
    }

    @Override
    public String name() {
        return "CHANGE_HEADER_PARAM_STRING";
    }
}
