package upp;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import org.antlr.runtime.ANTLRFileStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

public class Main {

	public static void main(String[] args) throws RecognitionException,
			IOException {
		if (args == null || args.length == 0) {
			System.out.println("Usage:");
			System.out.println("java -jar upp.jar input.file");
			return;
		}

		ANTLRFileStream fileStream = new ANTLRFileStream(args[0], "UTF-8");
		uppLexer lexer = new uppLexer(fileStream);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		uppParser parser = new uppParser(tokens);
		parser.file();

		System.out.println("Packages to remove:");
		printPackages(lexer.mapRemove);
		System.out.println();
		System.out.println();
		System.out.println("Packages to install:");
		printPackages(lexer.mapInstall);
		System.out.println();
		System.out.println();
		System.out.println("Optional packages:");
		printPackages(lexer.mapOptional);

		// First category is always the default "(no category)"
		if (lexer.cats.get(0).items.isEmpty())
			lexer.cats.remove(0);

		System.out.println();
		System.out.println();
		for (Category c : lexer.cats) {
			System.out.println(c.name);
			for (Item i : c.items)
				System.out.println("\t" + i.name);
		}

		for (Category c : lexer.cats) {
			System.out.println();
			System.out.println();
			System.out.println(c.name);

			for (Item i : c.items) {
				if (!i.hasFreeText)
					continue;
				System.out.println();
				System.out.println();
				System.out.print(i.text);
			}
		}
	}

	private static void printPackages(Map<String, List<String>> map) {
		for (Map.Entry<String, List<String>> entry : map.entrySet()) {
			System.out.println();
			System.out.println(entry.getKey());
			System.out.println(join(entry.getValue()));
		}
	}

	private static String join(List<String> list) {
		boolean first = true;
		StringBuilder sb = new StringBuilder();

		for (String s : list) {
			if (first)
				first = false;
			else
				sb.append(' ');

			sb.append(s);
		}

		return sb.toString();
	}

}
