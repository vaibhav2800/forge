package rezitests;

import java.util.Collections;
import java.util.List;

public class Category {

	/** Category ID used as GET param in URL */
	public final String GET_id;

	/** Category nr displayed on website's front page */
	public final int user_nr;

	/** Cateory name */
	public final String name;

	/** unmodifiable question list */
	public final List<Question> questions;

	/** Number of strike-through-ed questions */
	public final int striked_questions;

	public Category(CategHREF categHref, List<Question> questions) {
		this.GET_id = categHref.GET_id;
		this.user_nr = categHref.user_nr;
		this.name = categHref.name;
		this.questions = Collections.unmodifiableList(questions);

		int striked = 0;
		for (Question q : this.questions) {
			if (q.strike_title)
				striked++;
		}
		this.striked_questions = striked;
	}

	public String getFileName() {
		String n = name.replaceAll("[^-_a-zA-Z0-9 \\.,]", "");
		n = n.replaceAll("[.,]+", ".");
		n = n.replaceAll("[.]?[ ]+", ".");
		return user_nr + "." + n + ".id" + GET_id;
	}

}
