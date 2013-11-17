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
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class Anagram {

	public static void main(String[] args) {
		BufferedReader in = new BufferedReader(new InputStreamReader(System.in,
				Charset.forName("UTF-8")));
		BufferedWriter out = new BufferedWriter(new OutputStreamWriter(
				System.out));
		TextReader textReader = new WordReader(in);
		Map<CharsUsed, List<String>> anagramGroups = new HashMap<CharsUsed, List<String>>();
		Map<Set<Character>, List<String>> pseudoAnagGroups = new HashMap<Set<Character>, List<String>>();
		Set<String> knownWords = new HashSet<String>();

		try {
			String word;
			while ((word = textReader.readItem()) != null) {
				if (knownWords.contains(word))
					continue;
				knownWords.add(word);

				CharsUsed charsUsed = new CharsUsed(word);
				Set<Character> charsSet = charsUsed.getCharacters();

				List<String> list;

				list = anagramGroups.get(charsUsed);
				if (list == null) {
					list = new LinkedList<String>();
					anagramGroups.put(charsUsed, list);
				}
				list.add(word);

				list = pseudoAnagGroups.get(charsSet);
				if (list == null) {
					list = new LinkedList<String>();
					pseudoAnagGroups.put(charsSet, list);
				}
				list.add(word);
			}

			out.write("anagram groups: " + anagramGroups.size() + "\n");
			out.write("pseudo-anagram groups: " + pseudoAnagGroups.size()
					+ "\n");

			Comparator<Collection<?>> colSizeComp = new Comparator<Collection<?>>() {
				@Override
				public int compare(Collection<?> c1, Collection<?> c2) {
					// TODO: treat null args
					return c2.size() - c1.size();
				}
			};

			List<List<String>> anagrams = new ArrayList<List<String>>(
					anagramGroups.values());
			List<List<String>> pseudoAnagrams = new ArrayList<List<String>>(
					pseudoAnagGroups.values());
			Collections.sort(anagrams, colSizeComp);
			Collections.sort(pseudoAnagrams, colSizeComp);

			out.write("Anagrams:" + "\n");
			for (List<String> l : anagrams) {
				if (l.size() <= 1)
					break;
				print(l, out);
				out.write("\n");
			}

			out.write("\nPseudo Anagrams:" + "\n");
			for (List<String> l : pseudoAnagrams) {
				if (l.size() <= 1)
					break;
				print(l, out);
				out.write("\n");
			}
		} catch (IOException e) {
			System.err.println("IOException: " + e);
			e.printStackTrace();
		} finally {
			close(in);
			close(out);
		}
	}

	private static void close(Closeable object) {
		if (object == null)
			return;
		try {
			object.close();
		} catch (IOException e) {
			System.err.println("Exception closing " + object + ": " + e);
			e.printStackTrace();
		}
	}

	private static void print(Collection<String> l, Writer out)
			throws IOException {
		// TODO: check arg
		boolean notFirst = false;
		for (String s : l) {
			if (notFirst)
				out.write(" ");
			else
				notFirst = true;

			out.write(s);
		}
	}
}
