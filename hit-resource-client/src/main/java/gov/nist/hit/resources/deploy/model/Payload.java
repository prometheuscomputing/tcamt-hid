package gov.nist.hit.resources.deploy.model;

import java.io.File;
import java.io.InputStream;

import org.springframework.core.io.FileSystemResource;
import org.springframework.util.LinkedMultiValueMap;

import gov.nist.hit.resources.deploy.client.Utils;

public class Payload {
	
	private InputStream zipFile;
	private Long id;
	
	public Payload(InputStream zipFile, Long id) {
		super();
		this.zipFile = zipFile;
		this.id = id;
	}
	
	public Payload(InputStream zipFile) {
		super();
		this.zipFile = zipFile;
		this.id = -1L;
	}
	
	public InputStream getZipFile() {
		return zipFile;
	}
	public void setZipFile(InputStream zipFile) {
		this.zipFile = zipFile;
	}
	public Long getId() {
		return id;
	}
	public void setId(Long id) {
		this.id = id;
	}

	public LinkedMultiValueMap<String, Object> asMultiPartForm(Scope scope, String domain){
		LinkedMultiValueMap<String, Object> parts = new LinkedMultiValueMap<>();
		File f = Utils.toFile(zipFile, "bundle", ".zip");
		parts.add("file", new FileSystemResource(f));
		parts.add("id", id);
		parts.add("domain", domain);
		if(scope != null){
			parts.add("scope", scope);
		}
		return parts;
	}
}
