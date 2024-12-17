# Proposal: Introduce Relaxed Data Binding to Ballerina HTTP Module

_Owners_: @SachinAkash01  
_Reviewers_: @lnash94 @TharmiganK @shafreenAnfar    
_Created_: 2024/11/13  
_Updated_: 2024/11/18  
_Issue_: [#7366](https://github.com/ballerina-platform/ballerina-library/issues/7366)

## Summary

Using the projection support from conversion APIs from the data module, the HTTP module will add a fix by providing a configurable to handle undefined nillable property scenarios where the user can choose strict data binding or relaxed data binding.

## Goals
- Enhance the Ballerina HTTP module by adding support to handle undefined nillable properties where the users can choose strict data binding or relaxed data binding.

## Motivation
According to OpenAPI specification if a given property is required or/and nullable we need to specifically mention it as explained below.

If a given property is `required`,
```yaml
type: object
properties:
  id:
    type: integer
  username:
    type: string
required:
  - id
  - username
```

If a given property is `nullable`,
```yaml
type: integer
nullable: true
```

Therefore if a given property is not specifically mentioned as required, then that property is optional by default. Similarly if a given property is not specifically mentioned as `nullable: true`, then that property is not accepting null values by default.

There are several scenarios where the received response has null values even though that property is not configured as `nullable: true`. In such cases http target type binding fails, returning a type conversion error.

As a workaround, there is a `--nullable` flag to make all the fields nillable when it is not defined in the OpenAPI specification. However this approach also makes all the fields nullable which is not an ideal solution.

A more user-friendly solution is to implement relaxed data binding, which would allow the tool to accept null values for non-nullable fields without raising runtime errors. This approach would handle unexpected null values gracefully, reducing type conversion issues and enhancing the developer experience by aligning more closely with API responses.

## Description
Following is the breakdown of the cases we need to reconsider within the context of payload data binding:
<meta charset="utf-8"><b style="font-weight:normal;" id="docs-internal-guid-f6c8a312-7fff-fcbf-faf3-0b5d1af4efa6"><div dir="ltr" style="margin-left:0pt;" align="left">
Scenario | Ballerina Representation | Current Behavior | Expected Behavior
-- | -- | -- | --
Required & non-nullable | T foo; | Both null values and absent fields cause runtime failures | Same
Required & nullable | T? foo; | Absent fields will cause runtime failures | Need relaxed data binding to map absent fields as nil values
Optional & non-nullable | T foo?; | Null values will cause runtime failures | Need relaxed data binding to map null values as absent fields
Optional & nullable | T? foo?; | Both nil values and absent fields are allowed | Same

</div></b>

In the `data.jsondata` package, the `Options` configuration already provides support for handling various field types in JSON data binding, accommodating scenarios with both absent fields and nil values. The `Options` record allows us to adjust how nullability and optionality are treated, making it a versatile solution for managing the differences between required and optional fields, as well as nullable and non-nullable fields.

The `Options` record in the data.jsondata module is defined as follows:,

```ballerina
public type Options record {
    record {
        # If `true`, nil values will be considered as optional fields in the projection.
        boolean nilAsOptionalField = false;
        # If `true`, absent fields will be considered as nilable types in the projection.
        boolean absentAsNilableType = false;
    }|false allowDataProjection = {};
    boolean enableConstraintValidation = true;
};
```

This configuration offers flexibility through two primary settings,
- `nilAsOptionalField`: when set to `true`, nil values are treated as optional fields, allowing relaxed data binding for Optional and Non-Nullable cases. This way, null values in the input can be mapped into an absent field, avoiding runtime failures.
- `absentAsOptionalField`: when enabled, absent fields are interpreted as nullable, providing support for Required & Nullable cases by mapping absent fields into nil values  instead of causing runtime errors.

### Configure Relaxed Data Binding in Client Level
To enable relaxed data binding for the HTTP client at the client level, we can integrate the desired behavior into the `ClientConfiguration` settings. Using `ClientConfiguration`, we can adjust the handling of null values and absent fields, enhancing compatibility with APIs that return inconsistent field specifications.

The approach involves adding a new field, `laxDataBinding`, to the `CommonClientConfiguration` to enable relaxed data binding specifically for null and absent fields in the JSON payload. When `laxDataBinding` is set to `true`, it will internally map to enabling both `nilAsOptionalField` and `absentAsNilableType` in the `data.jsondata` module. This option will be enabled by default for clients generated using the Ballerina OpenAPI tool.

```ballerina
public type CommonClientConfiguration record {|
	boolean laxDataBinding = false;
	// Other fields
|};
```

### Configure Relaxed Data Binding in Service Level
We can configure the relaxed data binding in the service level by improving the `HttpServiceConfig` configuration by introducing a new boolean field called `laxDataBinding`, similar to the approach used in the client configuration.

```ballerina
public type HttpServiceConfig record {|
	boolean laxDataBinding = false;
	// Other fields
|};
```
