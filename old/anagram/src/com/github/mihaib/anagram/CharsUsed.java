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

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class CharsUsed {

	private Map<Character, Integer> charsUsed;

	public CharsUsed(String s) {
		charsUsed = new HashMap<Character, Integer>();
		for (Character c : s.toCharArray()) {
			Integer count = charsUsed.get(c);
			if (count == null)
				count = 0;
			charsUsed.put(c, count + 1);
		}
	}

	public Set<Character> getCharacters() {
		return charsUsed.keySet();
	}

	@Override
	public int hashCode() {
		return charsUsed.hashCode();
	}

	@Override
	public boolean equals(Object o) {
		if (o == null)
			return false;

		if (o instanceof CharsUsed)
			return charsUsed.equals(((CharsUsed) o).charsUsed);
		else
			return false;

	}

}
