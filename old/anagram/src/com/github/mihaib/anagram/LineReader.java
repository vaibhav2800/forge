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

public class LineReader extends TextReader {

	public LineReader(BufferedReader in) {
		super(in);
	}

	@Override
	public String readItem() throws IOException {
		return in.readLine();
	}

}
