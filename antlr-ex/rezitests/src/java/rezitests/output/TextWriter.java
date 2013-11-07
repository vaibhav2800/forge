package rezitests.output;

import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.Date;

import rezitests.Category;
import rezitests.Question;

public class TextWriter extends OutputWriter {

	private static final String strikeStr = "##";
	private static final String newLine = System.getProperty("line.separator",
			"\n");

	/** Used by writeHeading when writing to concatWriter */
	private boolean firstCateg = true;

	public TextWriter(File rootDir, Date date) throws IOException {
		super(rootDir, "txt", "all.txt", date);
		concatWriter.write("(indexed on " + timeStamp + ")" + newLine);
	}

	@Override
	public void writeCategory(Category category) throws IOException {
		String categFileName = category.getFileName();
		Writer categWriter = getWriter(categFileName + ".txt");

		try {
			writeHeading(category, categWriter);
			writeQuestions(category, categWriter);
			writeAnswers(category, categWriter);
		} finally {
			categWriter.close();
		}
	}

	/** Write heading to both categWriter and concatWriter */
	private void writeHeading(Category category, Writer categWriter)
			throws IOException {
		categWriter.write("(indexed on " + timeStamp + ")" + newLine);

		String categHeading = category.user_nr + ". " + category.name;
		categHeading += newLine + newLine + newLine;

		categWriter.write(categHeading);

		if (firstCateg)
			firstCateg = false;
		else
			concatWriter.write(newLine + newLine + newLine);

		concatWriter.write(categHeading);
	}

	/** Write questions to both categWriter and concatWriter */
	private void writeQuestions(Category category, Writer categWriter)
			throws IOException {
		boolean first = true;
		for (Question q : category.questions) {
			String output = getOutput(q);

			if (first)
				first = false;
			else
				output = newLine + output;

			categWriter.write(output);
			concatWriter.write(output);
		}
	}

	private static String getOutput(Question q) {
		StringBuilder sb = new StringBuilder();

		if (q.strike_title)
			sb.append(strikeStr);

		sb.append(q.nr + ". " + q.title + newLine);

		for (Question.Option o : q.options) {
			if (o.strike)
				sb.append(strikeStr);
			sb.append(o.ID + ". " + o.text + newLine);
		}

		return sb.toString();
	}

	/** Write answers to both categWriter and concatWriter */
	private void writeAnswers(Category category, Writer categWriter)
			throws IOException {
		String answerHeading = newLine + newLine + "Raspunsuri:" + newLine
				+ newLine;
		categWriter.write(answerHeading);
		concatWriter.write(answerHeading);

		boolean first = true;
		for (Question q : category.questions) {
			String s = q.nr + " " + q.answer;

			if (q.strike_answer)
				s = strikeStr + s;

			if (first)
				first = false;
			else
				s = "   " + s;

			categWriter.write(s);
			concatWriter.write(s);
		}

		categWriter.write(newLine);
		concatWriter.write(newLine);
	}

}
