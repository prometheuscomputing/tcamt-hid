package gov.nist.hit.resources.deploy.model;

public enum Action {
	
	ADD("add"),
	UPDATE("update"),
	ADD_OR_UPDATE("edit"),
	DELETE("delete");

	private String code;

	
	private Action(String code) {
		this.code = code;
	}

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}
	
	
}
