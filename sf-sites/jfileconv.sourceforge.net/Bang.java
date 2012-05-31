package tutorial.replace;

import java.io.IOException;
import java.io.Reader;

import com.github.mihaib.jfileconv.ReaderFactory;

public class Bang implements ReaderFactory {

	@Override
	public Reader getFilter(final Reader r) {
		return new Reader() {
			@Override
			public int read(char[] cbuf, int off, int len) throws IOException {
				len = r.read(cbuf, off, len);

				for (int i = off; i < off + len; i++) {
					if (cbuf[i] == 'i')
						cbuf[i] = '!';
				}

				return len;
			}

			@Override
			public void close() throws IOException {
				r.close();
			}
		};
	}

	@Override
	public String toString() {
		return "Bang: i -> !";
	}

	@Override
	public String getDescription() {
		return "Convert 'i' to '!'";
	}

}
