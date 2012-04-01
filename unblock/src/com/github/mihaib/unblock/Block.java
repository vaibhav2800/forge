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

import java.util.Comparator;

public class Block {

	public final int line, col, len;
	public final Direction dir;
	public final boolean isTarget;

	public Block(int line, int col, int len, Direction dir, boolean isTarget)
			throws BoardFormatException {
		if (line < 0 || col < 0 || len < 2 || dir == null)
			throw new IllegalArgumentException("bad block args: "
					+ "top-left coordinates (" + line + ", " + col
					+ ") must be >= 0, " + "length (" + len
					+ ") >= 2 and direction (" + dir + ") non-null.");

		if (isTarget && dir == Direction.VERTICAL)
			throw new BoardFormatException("Target block is vertical at line "
					+ (line + 1) + ", column " + (col + 1));

		this.line = line;
		this.col = col;
		this.len = len;
		this.dir = dir;
		this.isTarget = isTarget;
	}

	@Override
	public boolean equals(Object obj) {
		if (!(obj instanceof Block))
			return false;

		Block that = (Block) obj;
		return this.line == that.line && this.col == that.col
				&& this.dir == that.dir && this.len == that.len
				&& this.isTarget == that.isTarget;
	}

	/** Compares two blocks by their top-left corner */
	public final static Comparator<Block> topLeftComparator = new Comparator<Block>() {

		@Override
		public int compare(Block o1, Block o2) {
			if (o1.line == o2.line)
				return o1.col - o2.col;
			return o1.line - o2.line;
		}
	};

}
