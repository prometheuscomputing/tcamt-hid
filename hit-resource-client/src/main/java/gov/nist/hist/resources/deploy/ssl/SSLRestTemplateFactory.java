package gov.nist.hist.resources.deploy.ssl;

import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;

import org.apache.http.client.HttpClient;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.ssl.SSLContextBuilder;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

public class SSLRestTemplateFactory {

	@SuppressWarnings("deprecation")
	public static RestTemplate createSSLRestTemplate() throws KeyManagementException, NoSuchAlgorithmException, KeyStoreException {

		SSLConnectionSocketFactory socketFactory = 
				new SSLConnectionSocketFactory(new SSLContextBuilder().loadTrustMaterial(null, new TrustAllStrategy()).build(), SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
		HttpClient httpClient = HttpClients.custom().setSSLSocketFactory(socketFactory).setHostnameVerifier(SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER).build();
		HttpComponentsClientHttpRequestFactory fct = new HttpComponentsClientHttpRequestFactory(httpClient);
		return new RestTemplate(fct);

	}
}
