package sitecheck;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.net.URLConnection;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.Lexer;

public class WimiRetriever extends SiteRetriever {

	public WimiRetriever(String urlString, String userAgent)
			throws MalformedURLException {
		super(urlString, userAgent);
	}

	@Override
	public String getValue() throws IOException {
		URLConnection conn = url.openConnection();
		if (userAgent != null)
			conn.setRequestProperty("User-Agent", userAgent);
		BufferedReader br = new BufferedReader(new InputStreamReader(conn
				.getInputStream(), "UTF-8"));
		return br.readLine();
	}

	@Override
	protected Lexer getLexer(ANTLRInputStream input) {
		return null;
	}

	@Override
	protected SiteParser getParser(CommonTokenStream tokens) {
		return null;
	}

}
