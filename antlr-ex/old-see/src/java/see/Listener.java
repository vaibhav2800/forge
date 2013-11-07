package see;

/** Writes to stderr and counts `error' method invocations */
public class Listener {

	private int errors;

	public void error(String location, String msg) {
		write(location, "error", msg);
		errors++;
	}

	public void note(String location, String msg) {
		write(location, "note", msg);
	}

	public void write(String location, String msgType, String msg) {
		if (location != null && !location.isEmpty())
			System.err.print(location + ": ");
		if (msgType != null && !msgType.isEmpty())
			System.err.print(msgType + ": ");
		if (msg == null)
			msg = "";
		System.err.println(msg);
	}

	public int getErrors() {
		return errors;
	}

}
