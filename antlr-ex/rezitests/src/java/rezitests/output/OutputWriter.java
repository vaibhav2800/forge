package rezitests.output;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.text.SimpleDateFormat;
import java.util.Date;

import rezitests.Category;

public abstract class OutputWriter {

	protected final File outDir;
	protected final BufferedWriter concatWriter;
	protected final String timeStamp;

	protected OutputWriter(File rootDir, String subDirName,
			String concatFileName, Date date) throws IOException {
		outDir = new File(rootDir, subDirName);

		if (outDir.exists()) {
			System.err.println("Warning: dir " + outDir.getAbsolutePath()
					+ " exists.");
		} else {
			if (!outDir.mkdir()) {
				throw new IOException("Can't create directory "
						+ outDir.getAbsolutePath());
			}
		}

		concatWriter = getWriter(concatFileName);
		this.timeStamp = new SimpleDateFormat("MMMM dd, yyyy").format(date);
	}

	public abstract void writeCategory(Category category) throws IOException;

	public void close() throws IOException {
		concatWriter.close();
	}

	/** Returns a writer for the file (warns and overwrites if file exists) */
	protected BufferedWriter getWriter(String fileName) throws IOException {
		File file = new File(outDir, fileName);

		if (file.exists()) {
			System.err.println("Warning: file " + file.getAbsolutePath()
					+ " exists. Will overwrite.");
		}

		return new BufferedWriter(new OutputStreamWriter(new FileOutputStream(
				file), "UTF-8"));
	}

}
