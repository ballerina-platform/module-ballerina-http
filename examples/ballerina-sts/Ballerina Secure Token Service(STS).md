# Ballerina STS

## Overview

Ballerina Secure Token Service (STS) which supports OAuth2 token issuing and validation. This supports both HTTPS and 
HTTP on port 9445 and 9444 in order.

## Testing

As the first step, we have to run the 'STS' first. Open the terminal and execute the following command to run as a 
container.
```shell
$ docker run -p 9445:9445 -p 9444:9444 ldclakmal/ballerina-sts:latest
```

-- OR --

Execute the following command to run in the local machine.
```shell
$ bal run
```

#### Get an access token with a scope

```shell
$ curl -k -u FlfJYKBD2c925h4lkycqNZlC2l4a:PJz0UhTJMrHOo68QQNpvnqAY_3Aa \
-H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
-d "grant_type=client_credentials&scope=view-order" \
https://localhost:9445/oauth2/token
```

#### Refresh an access token with a scope

```shell
$ curl -k -u FlfJYKBD2c925h4lkycqNZlC2l4a:PJz0UhTJMrHOo68QQNpvnqAY_3Aa \
-H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
-d "grant_type=refresh_token&refresh_token=<REFRESH_TOKEN>&scope=view-order" \
https://localhost:9445/oauth2/token
```

#### Validate access token

```shell
$ curl -k -u admin:admin -H 'Content-Type: application/x-www-form-urlencoded' \
-d 'token=<ACCESS_TOKEN>' \
https://localhost:9445/oauth2/introspect
```
