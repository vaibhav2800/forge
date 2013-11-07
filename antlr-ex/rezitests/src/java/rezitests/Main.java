package rezitests;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.Lexer;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.Token;

import rezitests.output.HTMLWriter;
import rezitests.output.LatexWriter;
import rezitests.output.OutputWriter;
import rezitests.output.TextWriter;

public class Main {

	/** ExecutorService used to fetch all questions in a category */
	private static final ExecutorService executor = Executors
			.newFixedThreadPool(5);

	public static void main(String[] args) {
		List<CategHREF> categHrefs;

		try {
			System.out.print("Connecting.. ");
			categHrefs = getCategHrefs();
			System.out.println("found " + categHrefs.size() + " categories");
		} catch (Exception e) {
			System.err.println(e);
			System.exit(1);
			return;
		}

		Date now = new Date();
		String timeStamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(now);

		File outDir = makeOutDirOrExit(timeStamp);
		List<OutputWriter> writers = getWriters(outDir, now);

		int pageCount = 0;
		int qCount = 0, qStrikeCount = 0;

		for (CategHREF categHref : categHrefs) {
			System.out.printf("%2d [%-25.25s].. ", categHref.user_nr,
					categHref.name);

			List<String> pageLinks;
			try {
				pageLinks = getPageLinks(categHref.GET_id);
			} catch (Exception e) {
				System.err.println(e);
				continue;
			}

			System.out.printf("download %2d pages.. ", pageLinks.size());
			pageCount += pageLinks.size();

			Category category = new Category(categHref, getQuestions(pageLinks));

			int crt_qCount = category.questions.size();
			int crt_qStrike = category.striked_questions;
			System.out.printf("%d questions (%d, #%d)\n", crt_qCount,
					crt_qCount - crt_qStrike, crt_qStrike);

			qCount += crt_qCount;
			qStrikeCount += crt_qStrike;

			writeData(writers, category);
		}

		executor.shutdown();

		for (OutputWriter w : writers) {
			try {
				w.close();
			} catch (IOException e) {
				System.err.println(e);
			}
		}

		System.out.printf("Total: %d website pages, "
				+ "%d questions (%d + #%d --strikethrough--)\n", pageCount,
				qCount, qCount - qStrikeCount, qStrikeCount);
	}

	private static List<CategHREF> getCategHrefs() throws IOException {
		InputStream in = null;
		try {
			URL url = new URL("http://www.rezitests.ro/intrebari.php");
			in = url.openConnection().getInputStream();
			Lexer lexer = new CategoriesLexer(new ANTLRInputStream(in, "UTF-8"));

			List<CategHREF> categHrefs = new ArrayList<CategHREF>();

			while (true) {
				Token token = lexer.nextToken();
				if (token.getType() == Token.EOF)
					break;
				categHrefs.add(new CategHREF(token.getText()));
			}

			return categHrefs;
		} finally {
			if (in != null)
				in.close();
		}
	}

	/**
	 * Make output directory and return it. Exit if already exists or can't
	 * create it.
	 */
	private static File makeOutDirOrExit(String timeStamp) {
		File outDir = new File("./rezitests-" + timeStamp);

		if (outDir.exists()) {
			System.err.println("ERROR: Directory " + outDir.getAbsolutePath()
					+ " exits.");
			System.exit(1);
		}

		if (!outDir.mkdir()) {
			System.err.println("ERROR: Can't make directory "
					+ outDir.getAbsolutePath());
			System.exit(1);
		}

		return outDir;
	}

	private static List<OutputWriter> getWriters(File outDir, Date date) {
		List<OutputWriter> writers = new ArrayList<OutputWriter>();

		try {
			writers.add(new TextWriter(outDir, date));
		} catch (Exception e) {
			System.err.println(e);
		}

		try {
			writers.add(new HTMLWriter(outDir, date));
		} catch (Exception e) {
			System.err.println(e);
		}

		try {
			writers.add(new LatexWriter(outDir, date));
		} catch (Exception e) {
			System.err.println(e);
		}

		return writers;
	}

	private static List<String> getPageLinks(String GET_id) throws IOException,
			RecognitionException {
		InputStream in = null;
		try {
			URL url = new URL("http://www.rezitests.ro/intrebari_tema.php"
					+ "?idTema=" + GET_id);
			in = url.openConnection().getInputStream();

			Lexer lexer = new PageLinksLexer(new ANTLRInputStream(in, "UTF-8"),
					GET_id);
			CommonTokenStream tokens = new CommonTokenStream(lexer);
			PageLinksParser parser = new PageLinksParser(tokens);

			return parser.page_links();
		} finally {
			if (in != null)
				in.close();
		}
	}

	/** Retrieves Questions from all pages and handles any errors */
	private static List<Question> getQuestions(List<String> pageLinks) {
		/*
		 * Getting the questions from one page is one task. Submit all tasks to
		 * the executor, then block on each task waiting for its result.
		 */
		List<Future<List<Question>>> pendingResults = new ArrayList<Future<List<Question>>>(
				pageLinks.size());

		for (final String pageLink : pageLinks) {
			pendingResults.add(executor.submit(new Callable<List<Question>>() {
				@Override
				public List<Question> call() throws IOException,
						RecognitionException {
					return getQuestions(pageLink);
				}
			}));
		}

		List<Question> questions = new ArrayList<Question>();
		for (Future<List<Question>> pendingResult : pendingResults) {
			try {
				questions.addAll(pendingResult.get());
			} catch (ExecutionException e) {
				System.err.println("ERROR: " + e.getCause() + " with page "
						+ pageLinks.get(pendingResults.indexOf(pendingResult)));
			} catch (InterruptedException e) {
				System.err.println("Unexpected ERROR: " + e + "with page "
						+ pageLinks.get(pendingResults.indexOf(pendingResult)));
			}
		}

		return questions;
	}

	/** Retrieves the questions from a single page */
	private static List<Question> getQuestions(String pageLink)
			throws IOException, RecognitionException {
		InputStream in = null;
		try {
			URL url = new URL("http://www.rezitests.ro/" + pageLink);
			in = url.openConnection().getInputStream();

			Lexer lexer = new QuestionsLexer(new ANTLRInputStream(in, "UTF-8"));
			CommonTokenStream tokens = new CommonTokenStream(lexer);
			QuestionsParser parser = new QuestionsParser(tokens);

			return parser.questions();
		} finally {
			if (in != null)
				in.close();
		}
	}

	private static void writeData(List<OutputWriter> writers, Category category) {
		for (OutputWriter w : writers) {
			try {
				w.writeCategory(category);
			} catch (IOException e) {
				System.err.println(e);
			}
		}
	}

}
