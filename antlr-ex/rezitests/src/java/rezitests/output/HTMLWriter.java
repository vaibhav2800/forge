package rezitests.output;

import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.Date;

import rezitests.Category;
import rezitests.Question;

public class HTMLWriter extends OutputWriter {

	public HTMLWriter(File rootDir, Date date) throws IOException {
		super(rootDir, "html", "all.html", date);
		writeCSS();
		writeHTMLStart(concatWriter, "ReziTests – " + timeStamp);
		concatWriter.write("<h2>ReziTests</h2>\n\n");
		concatWriter.write("<p>(Indexed on " + timeStamp + ")</p>\n\n");
	}

	private void writeCSS() throws IOException {
		Writer cssW = getWriter("stylesheet.css");
		try {
			cssW.write("@charset \"utf-8\";\n\n");

			cssW.write("ol {\n");
			cssW.write("\tlist-style-type: upper-alpha;\n");
			cssW.write("}\n\n");

			cssW.write(".cut {\n");
			cssW.write("\ttext-decoration: underline;\n");
			cssW.write("\tfont-style: italic;\n");
			cssW.write("}\n");
		} finally {
			cssW.close();
		}
	}

	private static void writeHTMLStart(Writer htmlW, String title)
			throws IOException {
		htmlW.write("<!DOCTYPE html PUBLIC "
				+ "\"-//W3C//DTD XHTML 1.0 Strict//EN\"\n");
		htmlW.write("\"http://www.w3.org/TR/xhtml1/"
				+ "DTD/xhtml1-strict.dtd\">\n\n");
		htmlW.write("<html xmlns=\"http://www.w3.org/1999/xhtml\">\n\n");

		htmlW.write("<head>\n");
		htmlW.write("<meta http-equiv=\"Content-type\" "
				+ "content=\"text/html;charset=UTF-8\" />\n");
		htmlW.write("<link rel=\"stylesheet\" type=\"text/css\" "
				+ "href=\"stylesheet.css\" />\n");
		htmlW.write("<title>" + title + "</title>\n");
		htmlW.write("</head>\n\n");

		htmlW.write("<body>\n\n");
	}

	private static void writeHTMLEnd(Writer htmlW) throws IOException {
		htmlW.write("</body>\n\n");
		htmlW.write("</html>\n");
	}

	@Override
	public void close() throws IOException {
		writeHTMLEnd(concatWriter);
		super.close();
	}

	@Override
	public void writeCategory(Category category) throws IOException {
		String categFileName = category.getFileName();
		Writer categWriter = getWriter(categFileName + ".html");

		try {
			writeHTMLStart(categWriter, category.name + " – " + timeStamp);
			writeCategHeading(category, categWriter);
			writeQuestions(category, categWriter);
			writeAnswers(category, categWriter);
			writeHTMLEnd(categWriter);
		} finally {
			categWriter.close();
		}
	}

	/** Write category name to both categWriter and concatWriter */
	private void writeCategHeading(Category category, Writer categWriter)
			throws IOException {
		String heading = "<h2>" + category.user_nr + ". " + category.name
				+ "</h2>\n\n";
		categWriter.write(heading);
		categWriter.write("<p>(Indexed on " + timeStamp + ")</p>\n\n");
		concatWriter.write(heading);
	}

	/** Write questions to both categWriter and concatWriter */
	private void writeQuestions(Category category, Writer categWriter)
			throws IOException {
		for (Question q : category.questions) {
			String output = getOutput(q);

			categWriter.write(output);
			concatWriter.write(output);
		}
	}

	private static String getOutput(Question q) {
		StringBuilder sb = new StringBuilder();

		sb.append("<p");
		if (q.strike_title)
			sb.append(" class=\"cut\"");
		sb.append(">" + q.nr + ". " + q.title + "</p>\n");

		sb.append("<ol>\n");
		for (Question.Option o : q.options) {
			sb.append("\t<li");
			if (o.strike)
				sb.append(" class=\"cut\"");
			sb.append(">" + o.text + "</li>\n");
		}
		sb.append("</ol>\n\n");

		return sb.toString();
	}

	/** Write answers to both categWriter and concatWriter */
	private void writeAnswers(Category category, Writer categWriter)
			throws IOException {
		String answerHeading = "<h3>Raspunsuri:</h3>\n\n" + "<p>\n";
		categWriter.write(answerHeading);
		concatWriter.write(answerHeading);

		for (Question q : category.questions) {
			String s = q.nr + "&nbsp;" + q.answer;

			if (q.strike_answer)
				s = "<span class=\"cut\">" + s + "</span>";

			s += " &nbsp;&nbsp;\n";

			categWriter.write(s);
			concatWriter.write(s);
		}

		String answerEnd = "</p>\n\n";
		categWriter.write(answerEnd);
		concatWriter.write(answerEnd);
	}

}
