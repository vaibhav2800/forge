package sitecheck;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.Lexer;
import org.antlr.runtime.RecognitionException;

public abstract class SiteRetriever {

	protected final URL url;
	protected final String userAgent;

	protected SiteRetriever(String urlString, String userAgent)
			throws MalformedURLException {
		url = new URL(urlString);
		this.userAgent = userAgent;
	}

	protected abstract Lexer getLexer(ANTLRInputStream input);

	protected abstract SiteParser getParser(CommonTokenStream tokens);

	public String getValue() throws IOException, RecognitionException {
		URLConnection conn = url.openConnection();
		if (userAgent != null)
			conn.setRequestProperty("User-Agent", userAgent);
		ANTLRInputStream input = new ANTLRInputStream(conn.getInputStream(),
				"UTF-8");
		Lexer lexer = getLexer(input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		SiteParser parser = getParser(tokens);
		return parser.page();
	}

	public static SiteRetriever getInstance(String grammarName, String url,
			String userAgent) throws UnknownGrammarException,
			MalformedURLException {
		if (grammarName.equalsIgnoreCase("Emag")) {
			return new EmagRetriever(url, userAgent);
		} else if (grammarName.equalsIgnoreCase("PCgarage")) {
			return new PCgarageRetriever(url, userAgent);
		} else if (grammarName.equalsIgnoreCase("WhatIsMyIp")
				|| grammarName.equalsIgnoreCase("wimi")) {
			return new WimiRetriever(url, userAgent);
		} else if (grammarName.equalsIgnoreCase("Amazon")) {
			return new AmazonRetriever(url, userAgent);
		} else {
			throw new UnknownGrammarException("Unknown grammar: \""
					+ grammarName + "\"");
		}
	}

	/**
	 * Checks if user should be notified after interpreting the args in a
	 * retriever-specific manner.
	 */
	public boolean mustNotify(String notifyOver, String lastVal, String crtVal) {
		if (crtVal == null) {
			System.err.println("crtVal is null for " + getClass().getName());
			return true;
		}

		return !crtVal.equals(lastVal);
	}

}
