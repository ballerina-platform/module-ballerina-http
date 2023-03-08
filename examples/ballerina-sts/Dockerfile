FROM ballerina/ballerina:2201.0.0
LABEL maintainer="ldclakmal@gmail.com"
ADD target/bin/ballerina_sts.jar /home/ballerina/ballerina_sts.jar
ADD cert/private.key /home/ballerina/cert/private.key
ADD cert/public.crt /home/ballerina/cert/public.crt
USER ballerina
EXPOSE 9445
EXPOSE 9444
CMD bal run ballerina_sts.jar
