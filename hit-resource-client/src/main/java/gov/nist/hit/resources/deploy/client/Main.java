package gov.nist.hit.resources.deploy.client;

import java.io.IOException;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;

import gov.nist.hit.resources.deploy.exception.UserNotFoundException;

public class Main {

	public static void main(String[] args) throws KeyManagementException, NoSuchAlgorithmException, KeyStoreException, IOException, UserNotFoundException {
		SSLHL7v2ResourceClient client = new SSLHL7v2ResourceClient("http://localhost:8080/gvt/", "hossam", "12QWASZx");
		System.out.println(client.validCredentials());
	}
}
