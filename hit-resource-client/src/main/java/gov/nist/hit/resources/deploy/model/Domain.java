package gov.nist.hit.resources.deploy.model;

import java.util.HashSet;
import java.util.Set;



public class Domain {

	  private Long id;
	  private String name;
	  private String homeTitle;
	  private boolean disabled = false;
	  private String messageContentInfo;
	  private String homeContent;
	  private String profileInfo;
	  private String valueSetCopyright;
	  private String validationResultInfo;
	  private Set<String> participantEmails = new HashSet<String>();
	  private String rsbVersion;
	  private String igVersion;
	  private String owner;
	  private Scope scope;
	  
	public Long getId() {
		return id;
	}
	public void setId(Long id) {
		this.id = id;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public String getHomeTitle() {
		return homeTitle;
	}
	public void setHomeTitle(String homeTitle) {
		this.homeTitle = homeTitle;
	}
	public boolean isDisabled() {
		return disabled;
	}
	public void setDisabled(boolean disabled) {
		this.disabled = disabled;
	}
	public String getMessageContentInfo() {
		return messageContentInfo;
	}
	public void setMessageContentInfo(String messageContentInfo) {
		this.messageContentInfo = messageContentInfo;
	}
	public String getHomeContent() {
		return homeContent;
	}
	public void setHomeContent(String homeContent) {
		this.homeContent = homeContent;
	}
	public String getProfileInfo() {
		return profileInfo;
	}
	public void setProfileInfo(String profileInfo) {
		this.profileInfo = profileInfo;
	}
	public String getValueSetCopyright() {
		return valueSetCopyright;
	}
	public void setValueSetCopyright(String valueSetCopyright) {
		this.valueSetCopyright = valueSetCopyright;
	}
	public String getValidationResultInfo() {
		return validationResultInfo;
	}
	public void setValidationResultInfo(String validationResultInfo) {
		this.validationResultInfo = validationResultInfo;
	}
	public Set<String> getParticipantEmails() {
		return participantEmails;
	}
	public void setParticipantEmails(Set<String> participantEmails) {
		this.participantEmails = participantEmails;
	}
	public String getRsbVersion() {
		return rsbVersion;
	}
	public void setRsbVersion(String rsbVersion) {
		this.rsbVersion = rsbVersion;
	}
	public String getIgVersion() {
		return igVersion;
	}
	public void setIgVersion(String igVersion) {
		this.igVersion = igVersion;
	}
	public String getOwner() {
		return owner;
	}
	public void setOwner(String owner) {
		this.owner = owner;
	}
	public Scope getScope() {
		return scope;
	}
	public void setScope(Scope scope) {
		this.scope = scope;
	}
	  
	  
}
