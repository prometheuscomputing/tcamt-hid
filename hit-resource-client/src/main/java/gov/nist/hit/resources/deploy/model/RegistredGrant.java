package gov.nist.hit.resources.deploy.model;

public enum RegistredGrant {
	DEPLOYER,
	SUPERVISOR,
	OTHER;
	
	public static RegistredGrant fromString(String permission){
		switch(permission){
		case "deployer": return RegistredGrant.DEPLOYER;
		case "supervisor": return RegistredGrant.SUPERVISOR;
		default : return RegistredGrant.OTHER;
		}
	}
}
