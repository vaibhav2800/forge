package rezitests;

import java.util.Collections;
import java.util.List;

public class Question {

	public static class Option {
		public final String ID;
		public final String text;

		/** option was strikethroughed in HTML */
		public final boolean strike;

		public Option(String ID, String text) {
			this(ID, text, false);
		}

		public Option(String ID, String text, boolean strike) {
			this.ID = ID;
			this.text = text;
			this.strike = strike;
		}
	}

	public final int nr;
	public final String title;
	public final boolean strike_title;

	/** unmodifiable option list */
	public final List<Option> options;

	/** answer of the form "ABE" */
	public final String answer;
	public final boolean strike_answer;

	public Question(int nr, String title, List<Option> options, String answer) {
		this(nr, title, false, options, answer, false);
	}

	public Question(int nr, String title, boolean strike_title,
			List<Option> options, String answer, boolean strike_answer) {
		this.nr = nr;
		this.title = title;
		this.strike_title = strike_title;
		this.options = Collections.unmodifiableList(options);
		this.answer = answer;
		this.strike_answer = strike_answer;
	}

}
