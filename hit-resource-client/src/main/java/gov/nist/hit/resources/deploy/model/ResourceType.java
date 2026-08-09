package gov.nist.hit.resources.deploy.model;

public enum ResourceType {
	TEST_PLAN("tp"), 
	TEST_CASE("cbtc"), 
	TEST_CASE_GROUP("tg"), 
	TEST_STEP("ts"), 
	CF_TEST_CASE("cftc"), 
	PROFILE("profile"), 
	CONSTRAINTS("constraints"), 
	VALUE_SET("vs");

	private String code;

	private ResourceType(String code) {
		this.code = code;
	}

	public String getCode() {
		return code;
	}

	public void setCode(String code) {
		this.code = code;
	}
}
