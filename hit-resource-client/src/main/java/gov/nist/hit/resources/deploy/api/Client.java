package gov.nist.hit.resources.deploy.api;

import java.io.InputStream;
import java.util.List;
import java.util.Set;

import org.springframework.http.ResponseEntity;

import gov.nist.hit.resources.deploy.exception.InsupportedApiMethod;
import gov.nist.hit.resources.deploy.exception.UserNotFoundException;
import gov.nist.hit.resources.deploy.model.Domain;
import gov.nist.hit.resources.deploy.model.Payload;
import gov.nist.hit.resources.deploy.model.RegistredGrant;
import gov.nist.hit.resources.deploy.model.ResourceType;
import gov.nist.hit.resources.deploy.model.Scope;

public interface Client {

	public ResponseEntity<String> update(Payload model, ResourceType entity) throws InsupportedApiMethod;
	public ResponseEntity<String> addOrUpdate(Payload model, ResourceType entity, Scope scope, String domain) throws InsupportedApiMethod;
	public ResponseEntity<String> add(Payload model, ResourceType entity, ResourceType container, Scope scope, String domain) throws InsupportedApiMethod;
	public ResponseEntity<String> delete(Long id, ResourceType entity) throws InsupportedApiMethod;
	public ResponseEntity<Domain[]> getDomainByUsername();
	public ResponseEntity<String> uploadZip(InputStream file, String domain);
	public Set<RegistredGrant> validCredentials() throws UserNotFoundException;
	
}
