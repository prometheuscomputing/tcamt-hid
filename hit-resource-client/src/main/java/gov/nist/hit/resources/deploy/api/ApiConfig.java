package gov.nist.hit.resources.deploy.api;

import gov.nist.hit.resources.deploy.exception.InsupportedApiMethod;
import gov.nist.hit.resources.deploy.model.Action;
import gov.nist.hit.resources.deploy.model.ResourceType;

public interface ApiConfig {

	public String urlFor(Action action, ResourceType entity, ResourceType container) throws InsupportedApiMethod;
	public String login();
}
