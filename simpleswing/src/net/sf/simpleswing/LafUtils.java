/*
 * Copyright © Mihai Borobocea 2009, 2010
 * 
 * This file is part of SimpleSwing.
 * 
 * SimpleSwing is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * SimpleSwing is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with SimpleSwing.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

package net.sf.simpleswing;

import java.util.Arrays;

import javax.swing.UIManager;
import javax.swing.UIManager.LookAndFeelInfo;

/**
 * Utilities for dealing with the Look And Feel.
 */
public class LafUtils {

	private static final LookAndFeelInfo[] availableLookAndFeels = UIManager
			.getInstalledLookAndFeels();
	private static final String[] lookAndFeelNames;

	static {
		lookAndFeelNames = new String[availableLookAndFeels.length];
		for (int i = 0; i < availableLookAndFeels.length; i++)
			lookAndFeelNames[i] = availableLookAndFeels[i].getName();
	}

	public static String[] getLookAndFeelNames() {
		return Arrays.copyOf(lookAndFeelNames, lookAndFeelNames.length);
	}

	public static LookAndFeelInfo[] getAvailableLookAndFeels() {
		return Arrays.copyOf(availableLookAndFeels,
				availableLookAndFeels.length);
	}

	/**
	 * Try to apply the specified look and feel. If not successful, try setting
	 * the System look and feel (on Windows and Mac) or Nimbus (on everything
	 * else). If these classes can't be found, try the cross-platform look and
	 * feel (currently Metal).
	 * 
	 * @param desiredLafClassName
	 *            the class name of the desired look and feel, or null
	 * @return the class name of the applied look and feel, or null
	 */
	public static String applyStartupLookAndFeel(String desiredLafClassName) {
		try {
			String clsName = desiredLafClassName;
			UIManager.setLookAndFeel(clsName);
			return clsName;
		} catch (Exception e) {
		}

		try {
			String clsName;
			if (isWindows() || isMacOS())
				clsName = UIManager.getSystemLookAndFeelClassName();
			else
				clsName = getLafClassName("Nimbus");
			if (clsName == null)
				UIManager.getCrossPlatformLookAndFeelClassName();
			UIManager.setLookAndFeel(clsName);
			return clsName;
		} catch (Exception e) {
		}

		return null;
	}

	/**
	 * Returns the class name of the LookAndFile class with the specified name,
	 * or null if no such class if found.
	 * 
	 * @param lafName
	 *            the user name for the look and feel (e.g. Metal)
	 * @return the class name of the implementing class if found, otherwise null
	 */
	public static String getLafClassName(String lafName) {
		if (lafName == null)
			return null;

		for (LookAndFeelInfo lafInfo : availableLookAndFeels)
			if (lafName.equalsIgnoreCase(lafInfo.getName()))
				return lafInfo.getClassName();

		return null;
	}

	/**
	 * Detects if the OS is Windows using the <code>os.name</code> system
	 * property
	 * 
	 * @return true if the <code>os.name</code> property starts with "windows",
	 *         false otherwise
	 */
	// TODO: make reference to the antlr sources
	public static boolean isWindows() {
		return System.getProperty("os.name").toLowerCase()
				.startsWith("windows");
	}

	/**
	 * Detects if the OS is Mac OS using the <code>os.name</code> system
	 * property
	 * 
	 * @return true if the <code>os.name</code> property starts with "mac os",
	 *         false otherwise
	 */
	public static boolean isMacOS() {
		return System.getProperty("os.name").toLowerCase().startsWith("mac os");
	}

}
