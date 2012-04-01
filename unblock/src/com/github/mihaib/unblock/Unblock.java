/*
 * Copyright © Mihai Borobocea 2011
 * 
 * This file is part of Unblock.
 * 
 * Unblock is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Unblock is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Unblock.  If not, see <http://www.gnu.org/licenses/>.
 * 
 */

package com.github.mihaib.unblock;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.util.Deque;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Set;

public class Unblock {

	public static void main(String[] args) {
		try {
			if (args.length != 1) {
				System.err.println("Usage: unblock board-file");
				System.exit(1);
			}

			CharsetDecoder decoder = Charset.forName("ASCII").newDecoder();
			BufferedReader r = new BufferedReader(new InputStreamReader(
					new FileInputStream(args[0]), decoder));
			Board start = new Board(r);

			if (start.isSolution()) {
				System.out.println(start);
				System.out.println("Solved in 0 moves.");
				return;
			}

			Set<Board> knownBoards = new HashSet<Board>();
			Queue<Board> pending = new LinkedList<Board>();
			pending.add(start);
			knownBoards.add(start);

			while (!pending.isEmpty()) {
				for (Board b : pending.remove().getChildren()) {
					if (knownBoards.contains(b))
						continue;

					if (b.isSolution()) {
						Deque<Board> stack = new LinkedList<Board>();
						while (b != null) {
							stack.addFirst(b);
							b = b.parent;
						}
						for (Board x : stack)
							System.out.println(x);
						int moves = stack.size() - 1;
						System.out.println("Solved in " + moves + " move"
								+ (moves > 1 ? "s" : "") + ".");

						return;
					}

					knownBoards.add(b);
					pending.add(b);
				}
			}

			System.out.println("No solution found.");
		} catch (Exception e) {
			System.err.println(e);
			System.exit(1);
		}
	}

}
