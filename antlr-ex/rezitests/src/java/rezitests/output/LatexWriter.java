package rezitests.output;

import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.Date;

import rezitests.Category;
import rezitests.Question;

public class LatexWriter extends OutputWriter {

	/** Writer for "comp.sh" script */
	private final BufferedWriter compScriptW;

	public LatexWriter(File rootDir, Date date) throws IOException {
		super(rootDir, "latex", "all.tex", date);

		writeStyle();

		compScriptW = getWriter("comp.sh");
		writeScripts();

		writeDocStart(concatWriter);
	}

	private void writeStyle() throws IOException {
		Writer styleW = getWriter("multchoice.sty");
		try {
			styleW.write("\\ProvidesPackage{multchoice}\n\n");
			styleW.write("\\usepackage{fontspec}\n");
			styleW.write("\\usepackage{xunicode}\n");
			styleW.write("\\usepackage{xltxtra}\n\n");

			styleW.write("\\usepackage{multicol}\n");
			styleW.write("\\usepackage{enumitem}\n");
			styleW.write("\\setitemize{nolistsep,leftmargin=*}\n\n");

			styleW.write("\\usepackage[top=1.7cm,bottom=1.7cm,"
					+ "left=1.2cm,right=1.2cm]{geometry}\n");
			styleW.write("\\usepackage{hyperref}\n\n");

			styleW.write("%make \\thedate available\n");
			styleW.write("\\usepackage{titling}\n");
			styleW.write("\\usepackage{fancyhdr}\n");
			styleW.write("%MUST set \\date{some date} in document,\n");
			styleW.write("%or you'll get an error when using this style:\n");
			styleW.write("\\fancypagestyle{rezitests-firstpage-style}{%\n");
			styleW.write("\\lhead{\\thedate}%\n");
			styleW.write("%\\renewcommand{\\headrulewidth}{0pt}%\n");
			styleW.write("}\n");
			styleW.write("\\pagestyle{fancy}\n");
		} finally {
			styleW.close();
		}
	}

	private void writeScripts() throws IOException {
		new File(outDir, "comp.sh").setExecutable(true);
		compScriptW.write("xelatex all.tex && xelatex all.tex");
		compScriptW.newLine();

		BufferedWriter cleanW = getWriter("clean.sh");
		try {
			new File(outDir, "clean.sh").setExecutable(true);
			cleanW.write("rm *.aux *.log *.out");
			cleanW.newLine();
			cleanW.close();
		} finally {
			cleanW.close();
		}
	}

	private void writeDocStart(Writer docW) throws IOException {
		docW.write("\\documentclass[a4paper]{article}\n\n");
		docW.write("\\usepackage{multchoice}\n\n");
		docW.write("\\begin{document}\n");
		docW.write("\\date{" + timeStamp + "}\n");
		docW.write("\\thispagestyle{rezitests-firstpage-style}\n\n");
	}

	private static void writeDocEnd(Writer docW) throws IOException {
		docW.write("\\end{document}\n");
	}

	@Override
	public void close() throws IOException {
		writeDocEnd(concatWriter);
		compScriptW.close();
		super.close();
	}

	@Override
	public void writeCategory(Category category) throws IOException {
		String docName = category.getFileName() + ".tex";
		String srcName = "src." + docName;

		// write "src.name.tex" file
		Writer srcW = getWriter(srcName);
		try {
			int sectionCounter = category.user_nr - 1;
			srcW.write("\\setcounter{section}{" + sectionCounter + "}\n");
			srcW.write("\\section");

			if (category.name.length() > 50) {
				String shortName = category.name.substring(0, 50);
				srcW.write("[" + escapeUserText(shortName) + "]");
			}

			srcW.write("{" + escapeUserText(category.name) + "}\n\n");
			srcW.write("\\begin{multicols}{2}\n");
			srcW.write("\\begin{itemize}\n\n");

			for (Question q : category.questions)
				writeQuestion(q, srcW);

			srcW.write("\\end{itemize}\n");
			srcW.write("\\end{multicols}\n\n\n");
			srcW.write("\\subsection{Răspunsuri}\n\n");

			for (Question q : category.questions) {
				String s = q.nr + "~" + escapeUserText(q.answer);

				if (q.strike_answer)
					s = "\\textit{" + s + "}";

				srcW.write(s + " ~~\n");
			}
		} finally {
			srcW.close();
		}

		// add "src.name.tex" to "all.tex"
		concatWriter.write("\\input{" + srcName + "}\n");

		// add "src.name.tex" to "name.tex"
		Writer docW = getWriter(docName);
		try {
			writeDocStart(docW);
			docW.write("\\input{" + srcName + "}\n");
			writeDocEnd(docW);
		} finally {
			docW.close();
		}

		// add "name.tex" to comp.sh
		compScriptW.write("xelatex " + docName + " && xelatex " + docName
				+ "\n");
	}

	/** Escape user text */
	private static String escapeUserText(String s) {
		StringBuilder sb = new StringBuilder();

		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);

			switch (c) {
			case '#':
			case '$':
			case '%':
			case '&':
			case '_':
			case '{':
			case '}':
				sb.append('\\');
				sb.append(c);
				break;

			case '~':
				sb.append("\\~{}");
				break;
			case '^':
				sb.append("\\textasciicircum{}");
				break;
			case '\\':
				sb.append("\\textbackslash{}");
				break;

			default:
				sb.append(c);
			}
		}

		return sb.toString();
	}

	private static void writeQuestion(Question q, Writer w) throws IOException {
		w.write("\\setlength{\\parskip}{15pt}\n");
		w.write("\\item[" + q.nr + "] ");

		if (q.strike_title)
			w.write("\\textit{");
		w.write(escapeUserText(q.title));
		if (q.strike_title)
			w.write("}");

		w.write("\n");
		w.write("\\setlength{\\parskip}{0pt}\n");

		w.write("\\begin{itemize}\n");
		for (Question.Option o : q.options) {
			w.write("\\item[" + escapeUserText(o.ID) + "] ");

			if (o.strike)
				w.write("\\textit{");
			w.write(escapeUserText(o.text));
			if (o.strike)
				w.write("}");

			w.write("\n");
		}
		w.write("\\end{itemize}\n\n");
	}

}
