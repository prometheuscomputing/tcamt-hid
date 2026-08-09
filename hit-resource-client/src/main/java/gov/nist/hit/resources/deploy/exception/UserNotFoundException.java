package gov.nist.hit.resources.deploy.exception;

public class UserNotFoundException extends Exception {

	/**
	 * 
	 */
	private static final long serialVersionUID = 5314955268576651639L;
	public UserNotFoundException(){
		super("The credetials are not valid");
	}

}
