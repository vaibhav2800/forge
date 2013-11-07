package rezitests;

/** Category data (name, GET_id, user_nr) from parser */
public class CategHREF {

	/** Category ID used as GET param in URL */
	final String GET_id;

	/** Category nr displayed on website's front page */
	final int user_nr;

	/** Cateory name */
	final String name;

	/** Takes string from parser "GETid<userNR<Name" e.g. "10<4<Name" */
	CategHREF(String s) {
		String[] x = s.split("<");
		if (x.length != 3) {
			throw new IllegalArgumentException("Invalid category string \"" + s
					+ "\". " + "Must be of form \"GETid<userNR<Name\" "
					+ "eg \"17<3<Name\"");
		}

		this.GET_id = x[0];
		this.user_nr = Integer.parseInt(x[1]);
		this.name = x[2];
	}

}
