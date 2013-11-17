/*
 * Copyright © Mihai Borobocea 2010
 * 
 * This file is part of Anagram.
 * 
 * Anagram is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Anagram is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Anagram.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

package com.github.mihaib.anagram;

import java.io.BufferedReader;
import java.io.IOException;

public abstract class TextReader {

	protected BufferedReader in;

	protected TextReader(BufferedReader in) {
		this.in = in;
	}

	/**
	 * Returns the next text item read from the BufferedReader, or
	 * <code>null</code> if no more items are available (i.e. EOF).
	 * 
	 * @return the next text item read from the Reader, or <code>null</code> if
	 *         EOF is reached.
	 * @throws IOException
	 */
	public abstract String readItem() throws IOException;

}
