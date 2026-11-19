/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contractimpl.common.certificatevalidation.CertificateVerificationException;
import io.ballerina.stdlib.http.transport.contractimpl.common.certificatevalidation.ocsp.OCSPCache;
import io.ballerina.stdlib.http.transport.contractimpl.common.certificatevalidation.ocsp.OCSPVerifier;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import org.bouncycastle.asn1.ocsp.OCSPResponseStatus;
import org.bouncycastle.cert.ocsp.BasicOCSPResp;
import org.bouncycastle.cert.ocsp.CertificateStatus;
import org.bouncycastle.cert.ocsp.OCSPException;
import org.bouncycastle.cert.ocsp.OCSPReq;
import org.bouncycastle.cert.ocsp.OCSPResp;
import org.bouncycastle.cert.ocsp.SingleResp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;

/**
 * A class for generating OCSP response.
 */
public class OCSPResponseBuilder {
    private OCSPResponseBuilder() {
    }

    private static final Logger LOG = LoggerFactory.getLogger(OCSPResponseBuilder.class);

    /**
     * Method to create a keystore and return.
     *
     * @param keyStoreFile     keyStore file
     * @param keyStorePassword keyStore password
     * @param tlsStoreType     PKCS12
     * @return keystore
     * @throws IOException Occurs if it fails to create the keystore.
     */
    public static KeyStore getKeyStore(File keyStoreFile, String keyStorePassword, String tlsStoreType)
            throws IOException {
        KeyStore keyStore = null;
        if (keyStoreFile != null && keyStorePassword != null) {
            try (InputStream inputStream = new FileInputStream(keyStoreFile)) {
                keyStore = KeyStore.getInstance(tlsStoreType);
                keyStore.load(inputStream, keyStorePassword.toCharArray());
            } catch (CertificateException | NoSuchAlgorithmException | KeyStoreException e) {
                throw new IOException(e);
            }
        }
        return keyStore;
    }

    /**
     * List Certificate authority url information.
     *
     * @param userCertificate User's own certificate.
     * @return AIA Locations
     * @throws CertificateVerificationException If an error occurs while getting the AIA locations from the certificate.
     */
    public static List<String> getAIALocations(X509Certificate userCertificate)
            throws CertificateVerificationException {
        List<String> locations;
        //List the AIA locations from the certificate. Those are the URL's of CA s.
        try {
            locations = OCSPVerifier.getAIALocations(userCertificate);
        } catch (CertificateVerificationException e) {
            throw new CertificateVerificationException("Failed to find AIA locations in the cetificate", e);
        }
        return locations;
    }

    /**
     * Get OCSP response from cache.
     *
     * @param locations       CA locations
     * @param request         OCSP request
     * @param userCertificate User's certificate
     * @param ocspCache       cache to store ocsp responses
     * @return Ocsp response
     * @throws CertificateVerificationException If an error occurs while getting the response.
     */
    public static OCSPResp getOCSPResponse(List<String> locations, OCSPReq request, X509Certificate userCertificate,
            OCSPCache ocspCache) throws CertificateVerificationException {
        SingleResp[] responses;
        BasicOCSPResp basicResponse;
        CertificateStatus certificateStatus;
        for (String serviceUrl : locations) {
            OCSPResp response;
            try {
                response = OCSPVerifier.getOCSPResponce(serviceUrl, request);
                if (OCSPResponseStatus.SUCCESSFUL != response.getStatus()) {
                    continue; // Server didn't give the correct response.
                }
                basicResponse = (BasicOCSPResp) response.getResponseObject();
                responses = (basicResponse == null) ? null : basicResponse.getResponses();
            } catch (OCSPException | CertificateVerificationException e) {
                LOG.debug("OCSP response failed for url{}. Hence trying the next url", serviceUrl);
                continue;
            }
            if (responses != null && responses.length == 1) {
                SingleResp singleResponse = responses[0];
                certificateStatus = singleResponse.getCertStatus();
                if (certificateStatus != null) {
                    throw new IllegalStateException("certificate-status=" + certificateStatus);
                }
                //User certificates serial number and response coming from CA needs to be same.
                if (!userCertificate.getSerialNumber().equals(singleResponse.getCertID().getSerialNumber())) {
                    throw new IllegalStateException(
                            "Bad Serials=" + userCertificate.getSerialNumber() + " vs. " + singleResponse.getCertID()
                                    .getSerialNumber());
                }                //If the response state is successful we cache the response.
                ocspCache.setCacheValue(response, userCertificate.getSerialNumber(), singleResponse, request,
                        serviceUrl);
                return response;
            }
        }
        throw new CertificateVerificationException("Could not get revocation status from OCSP.");
    }

    public static List<X509Certificate> getCertInfo(SSLConfig sslConfig) throws CertificateException, IOException {
        CertificateFactory certificateFactory = CertificateFactory.getInstance("X509");
        List<X509Certificate> certList = new ArrayList<>();
        try (FileInputStream certInputStream = new FileInputStream(sslConfig.getServerCertificates())) {
            while (certInputStream.available() > 1) {
                Certificate cert = certificateFactory.generateCertificate(certInputStream);
                certList.add((X509Certificate) cert);
            }
            return certList;
        }
    }
}

