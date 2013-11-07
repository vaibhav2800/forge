package sitecheck;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.Charset;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.antlr.runtime.RecognitionException;

public class Main {

	public static void main(String[] args) {
		String notifyCommand = null, globalUserAgent = null;
		try {
			ConfigFileReader cfr = new ConfigFileReader("site-check.cfg");
			notifyCommand = cfr.map.get("notify.command");
			globalUserAgent = cfr.map.get("User-Agent");
		} catch (IOException e) {
			// ignore
		} catch (RecognitionException e) {
			printErr(e, "site-check.cfg");
		}

		List<File> filesToCheck = getFilesToCheck();

		File outDir = new File("values");
		if (!outDir.exists()) {
			if (!outDir.mkdir()) {
				System.err.print("Failed to make directory ");
				System.err.println(outDir.getPath());
				return;
			}
		}

		String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());

		for (File crtFile : filesToCheck) {
			String fileParsed = null;
			try {
				// read source data
				fileParsed = crtFile.getPath();
				ConfigFileReader cfr = new ConfigFileReader(fileParsed);
				String grammar = cfr.map.get("grammar");
				String url = cfr.map.get("url");
				String notifyOver = cfr.map.get("notify-over");

				// get user-agent (specific overrides global)
				String userAgent = cfr.map.get("User-Agent");
				if (userAgent == null)
					userAgent = globalUserAgent;

				// check for required parameters
				if (grammar == null) {
					System.err.print("Missing grammar in " + crtFile.getPath());
					continue;
				}
				if (url == null) {
					System.err.print("Missing url in " + crtFile.getPath());
					continue;
				}

				// get most recent entry from outFile, if any
				File outFile = new File(outDir, crtFile.getName());
				ConfigParser.Entry lastEntry = null;

				if (outFile.exists()) {
					fileParsed = outFile.getPath();
					cfr = new ConfigFileReader(fileParsed);
					if (cfr.list.size() > 0)
						lastEntry = cfr.list.get(cfr.list.size() - 1);
				}

				// if most recent entry before today, read url and store value
				if (lastEntry == null || !today.equals(lastEntry.key)) {
					fileParsed = url;

					SiteRetriever retriever = SiteRetriever.getInstance(
							grammar, url, userAgent);
					String value = retriever.getValue();

					String lastNotify = getLastNotify(outDir, crtFile.getName());

					// notify user if value changed
					if (notifyCommand != null
							&& retriever.mustNotify(notifyOver, lastNotify,
									value)) {
						String command = notifyCommand;
						command += " " + crtFile.getName();
						command += " " + lastNotify;
						command += " " + value;
						command += " " + today;
						try {
							Runtime.getRuntime().exec(command);
						} catch (IOException e) {
							System.err.println(notifyCommand + ": " + e);
						}

						saveNotify(outDir, crtFile.getName(), value);
					}

					fileParsed = outFile.getPath();
					FileOutputStream fos = new FileOutputStream(outFile, true);
					OutputStreamWriter osw = new OutputStreamWriter(fos,
							Charset.forName("UTF-8"));
					BufferedWriter bw = new BufferedWriter(osw);
					bw.write(today + "=" + value + "\n");
					bw.close();
				}

			} catch (IOException e) {
				System.err.println(fileParsed + ": " + e);
			} catch (UnknownGrammarException e) {
				System.err.println(e);
			} catch (RecognitionException e) {
				printErr(e, fileParsed);
			}
		}
	}

	private static void printErr(RecognitionException e, String fileName) {
		fileName = fileName != null ? fileName : "<unknown file>";
		System.err.print("error in " + fileName + " at ");
		System.err.println(e.line + ":" + e.charPositionInLine + " " + e);
	}

	private static List<File> getFilesToCheck() {
		List<File> fileList = new ArrayList<File>();

		File dir = new File("items");
		File[] children = dir.listFiles();

		if (children == null)
			return fileList;

		for (File child : children) {
			if (child.isFile())
				fileList.add(child);
		}

		return fileList;
	}

	/** Get last user notification, or null. */
	private static String getLastNotify(File outDir, String itemName) {
		File notifyFile = new File(outDir, "notify." + itemName);

		try {
			if (notifyFile.exists()) {
				return new BufferedReader(new InputStreamReader(
						new FileInputStream(notifyFile), "UTF-8")).readLine();
			}
		} catch (IOException e) {
			System.err.println(notifyFile.getPath() + ": " + e);
		}

		return null;
	}

	private static void saveNotify(File outDir, String itemName,
			String notifyVal) {
		File notifyFile = new File(outDir, "notify." + itemName);

		try {
			BufferedWriter w = null;
			try {
				w = new BufferedWriter(new OutputStreamWriter(
						new FileOutputStream(notifyFile), "UTF-8"));
				w.write(notifyVal + "\n");
			} finally {
				w.close();
			}
		} catch (IOException e) {
			System.err.println(notifyFile.getPath() + ": " + e);
		}
	}

}
