package upp;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Stores the data for a single item in the upp config file.
 */
public class Item {

	/**
	 * This Item's name (a non-empty String).
	 */
	public final String name;
	/**
	 * This Item's label (non-null).
	 */
	public final String label;

	private final Map<PackageType, Map<String, String>> pckMaps = new HashMap<PackageType, Map<String, String>>();
	private final List<String> freeText = new ArrayList<String>();
	private String literalText = "";

	/**
	 * Creates a new Item with the specified <code>name</code> and no other
	 * initial data. The name must be a non-empty String. If the label is null,
	 * the newly created Item will have the empty String as label.
	 * 
	 * @param name
	 *            this Item's name, must be a non-empty String after trimming
	 * @param label
	 *            this Item's label, may be null (in which case the empty String
	 *            will be used for this Item's label)
	 * @throws IllegalArgumentException
	 *             if name is <code>null</code>, or an empty String
	 */
	public Item(String name, String label) throws IllegalArgumentException {
		if (name == null || name.trim().isEmpty())
			throw new IllegalArgumentException(
					"Item name must be non-empty String after trimming.");

		this.name = name.trim();
		this.label = label == null ? "" : label.trim();
	}

	/**
	 * Adds the specified String (after trimming) to this Item's list of
	 * freeText.
	 * 
	 * @param line
	 *            the text to add (if null, the empty String is added)
	 */
	public void addFreeText(String line) {
		freeText.add(line == null ? "" : line);
	}

	/**
	 * Returns an ArrayList with this Item's free text.
	 * 
	 * @return a copy of the internal List holding this Item's free text
	 */
	public List<String> getFreeText() {
		return new ArrayList<String>(freeText);
	}

	/**
	 * Adds packages with the specified label and type. If packages with the
	 * same type and label are present, the trimmed <code>packages</code> String
	 * is added to the existing one (separated by a space). If
	 * <code>label</code> or <code>packages</code> is null, that parameter is
	 * replaced with the empty String.
	 * 
	 * @param packages
	 *            String containing a package list
	 * @param label
	 *            label String for this package list
	 * @param type
	 *            the type of the new packages
	 */
	public void addPackages(String packages, String label, PackageType type) {
		if (label == null)
			label = "";
		if (packages == null)
			packages = "";

		label = label.trim();
		packages = packages.trim();
		packages.replaceAll("[ \\t]+", " ");

		Map<String, String> map = pckMaps.get(type);

		if (map == null) {
			map = new TreeMap<String, String>(String.CASE_INSENSITIVE_ORDER);
			pckMaps.put(type, map);
		}

		String value = map.get(label);
		if (value == null)
			value = "";

		map.put(label, (value + " " + packages).trim());
	}

	/**
	 * Returns a copy of the map for the specified package type.
	 * 
	 * @param type
	 *            the package type requested
	 * @return a copy of the Map<label, package_list> for the specified package
	 *         type
	 */
	public Map<String, String> getPackages(PackageType type) {
		Map<String, String> map = pckMaps.get(type);
		if (map == null)
			map = new TreeMap<String, String>();

		return new TreeMap<String, String>(map);
	}

	/**
	 * Set this Item's literal text (from which the data was extracted by the
	 * lexer/parser).
	 * 
	 * @param literalText
	 *            the Item's literal text (if null the empty String is used)
	 */
	public void setLiteralText(String literalText) {
		this.literalText = literalText == null ? "" : literalText;
	}

	/**
	 * Get this Item's literal text (the original which was parsed).
	 * 
	 * @return the Item's literal text if set, otherwise the empty String
	 */
	public String getLiteralText() {
		return literalText;
	}

}
