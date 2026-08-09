package gov.nist.hit.resources.deploy.client;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.commons.codec.binary.Base64;

public class Utils {

	public static File toFile(InputStream io, String name, String ext) {
		OutputStream outputStream = null;
		File f = null;
		try {
			
			f = File.createTempFile(name, ext);
			outputStream = new FileOutputStream(f);
			int read = 0;
			byte[] bytes = new byte[1024];
			while ((read = io.read(bytes)) != -1) {
				outputStream.write(bytes, 0, read);
			}
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (io != null) {
				try {
					io.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
			if (outputStream != null) {
				try {
					outputStream.close();
				} catch (IOException e) {
					e.printStackTrace();
				}

			}
		}
		return f;
	}
	
	public static String tokenize(String username, String password){
		String plainCreds = username+":"+password;
    	byte[] plainCredsBytes = plainCreds.getBytes();
    	byte[] base64CredsBytes = Base64.encodeBase64(plainCredsBytes);
    	return new String(base64CredsBytes);
	}
}
