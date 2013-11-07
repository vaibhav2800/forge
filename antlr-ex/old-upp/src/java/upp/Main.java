package upp;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import org.antlr.runtime.ANTLRFileStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

public class Main {

	public static void main(String[] args) throws IOException,
			RecognitionException {
		if (args == null || args.length == 0) {
			System.out.println("Usage:");
			System.out.println("java -jar upp.jar upp.config.file");
			return;
		}

		ANTLRFileStream fileStream = new ANTLRFileStream(args[0], "UTF-8");
		uppLexer lexer = new uppLexer(fileStream);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		uppParser parser = new uppParser(tokens);
		parser.upp_config_file();

		List<Item> items = lexer.getItems();
		Item masterItem = new Item("master", null);
		for (Item item : items) {
			for (PackageType type : PackageType.values()) {
				Map<String, String> crtMap = item.getPackages(type);
				for (Map.Entry<String, String> e : crtMap.entrySet())
					masterItem.addPackages(e.getValue(), e.getKey(), type);
			}
		}

		System.out.println("Packages to install:");
		Map<String, String> mandMap = masterItem
				.getPackages(PackageType.MANDATORY);
		for (Map.Entry<String, String> e : mandMap.entrySet()) {
			String label = e.getKey(), pck = e.getValue();
			System.out.println("@" + (label.isEmpty() ? "" : label + "@"));
			System.out.println(pck);
			System.out.println();
		}

		System.out.println("Optional packages:");
		Map<String, String> optMap = masterItem
				.getPackages(PackageType.OPTIONAL);
		for (Map.Entry<String, String> e : optMap.entrySet()) {
			String label = e.getKey(), pck = e.getValue();
			System.out.println("?" + (label.isEmpty() ? "" : label + "?"));
			System.out.println(pck);
			System.out.println();
		}

		System.out.println("Unwanted packages:");
		Map<String, String> unwMap = masterItem
				.getPackages(PackageType.UNWANTED);
		for (Map.Entry<String, String> e : unwMap.entrySet()) {
			String label = e.getKey(), pck = e.getValue();
			System.out.println("^" + (label.isEmpty() ? "" : label + "^"));
			System.out.println(pck);
			System.out.println();
		}

		for (Item item : items) {
			if (!item.getFreeText().isEmpty())
				System.out.println(item.getLiteralText());
		}
	}

}
