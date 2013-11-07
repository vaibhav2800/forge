package sitecheck;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.List;
import java.util.Map;

import org.antlr.runtime.ANTLRReaderStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

public class ConfigFileReader {

	public final Map<String, String> map;
	public final List<ConfigParser.Entry> list;

	public ConfigFileReader(String fileName) throws IOException,
			RecognitionException {
		BufferedReader br = null;
		try {
			FileInputStream fis = new FileInputStream(fileName);
			InputStreamReader isr = new InputStreamReader(fis, Charset
					.forName("UTF-8"));
			br = new BufferedReader(isr);

			ANTLRReaderStream rs = new ANTLRReaderStream(br);
			ConfigLexer lexer = new ConfigLexer(rs);
			CommonTokenStream tokens = new CommonTokenStream(lexer);
			ConfigParser parser = new ConfigParser(tokens);

			ConfigParser.file_return data = parser.file();
			map = data.map;
			list = data.list;
		} finally {
			if (br != null)
				br.close();
		}
	}

}
