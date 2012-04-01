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
import java.io.EOFException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * An immutable valid board state. May store the parent Board and the Move made
 * to obtain it from the parent, if the information is provided to the
 * constructor.
 */
public class Board {

	/** Keeps track of used/free cells */
	private boolean[][] used;
	public final int lines, cols;
	/** Blocks sorted in order of their top-left corner */
	private List<Block> blocks;

	/** hashCode computed and stored on first request */
	private int hashCode;
	private boolean hashCodeComputed;

	/** Parent board, or null */
	public final Board parent;

	private static boolean isValidChar(char c) {
		return c == '.' || c == '*' || (c >= '0' && c <= '9')
				|| (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
	}

	/**
	 * Reads a char matrix representing a board, at least 1 line, all lines the
	 * same length. See the constructor comment for why this method requires a
	 * BufferedReader (and not just a Reader).
	 * 
	 * @throws EOFException
	 *             if EOF reached without finding board data
	 */
	private static char[][] readMatrix(BufferedReader r) throws EOFException,
			IOException, BoardFormatException {
		String line;

		// allow leading empty (or whitespace-only) lines
		do {
			line = r.readLine();
			if (line == null)
				throw new EOFException("No board found");
			line = line.trim();
		} while (line.isEmpty());

		// read board matrix until EOF or empty (whitespace-only) line
		int cols = line.length();
		List<char[]> lines = new ArrayList<char[]>();
		for (; line != null; line = r.readLine()) {
			line = line.trim();
			if (line.isEmpty())
				break;

			if (line.length() != cols) {
				throw new BoardFormatException("Line " + (lines.size() + 1)
						+ " has length " + line.length() + ", expected " + cols);
			}

			char[] chars = line.toCharArray();
			for (int i = 0; i < cols; i++) {
				if (!isValidChar(chars[i]))
					throw new BoardFormatException("Invalid character at "
							+ "line " + (lines.size() + 1) + ":" + (i + 1));
			}
			lines.add(chars);
		}

		return lines.toArray(new char[0][]);
	}

	/**
	 * Returns the Block with the top-left corner at (line, col). It does only
	 * as few operations as needed when removing blocks from the map and
	 * checking for adjacency. For this reason, the caller must follow the rules
	 * below.
	 * 
	 * This function must be called, in order (rows from top to bottom, within
	 * each row from left to right), for each non-empty cell in the matrix. It
	 * deletes vertical blocks from the map (replaces them with '.') but not
	 * horizontal ones. The caller, when searching for non-empty cells, must
	 * advance the length of a horizontal block that has been returned by this
	 * function (as that block is not removed). When checking for adjacency, it
	 * looks to the left & right of vertical blocks, but only below horizontal
	 * ones.
	 * 
	 * @throws BoardFormatException
	 *             if the block is found to be of length 1 or adjacent to
	 *             another using the above rules.
	 */
	private static Block getBlock(char[][] mat, final int line, final int col)
			throws BoardFormatException {
		int i = line, j = col;
		final char c = mat[i][j];
		final Direction dir;
		if (i + 1 < mat.length && mat[i + 1][j] == c)
			dir = Direction.VERTICAL;
		else
			dir = Direction.HORIZONTAL;

		int len = 0;
		boolean split = false;
		while (i < mat.length && j < mat[i].length && mat[i][j] == c) {
			split = true;
			if (dir == Direction.HORIZONTAL) {
				if (i + 1 < mat.length && mat[i + 1][j] == c)
					break;

				j++;
			} else {
				if (j - 1 >= 0 && mat[i][j - 1] == c)
					break;
				if (j + 1 < mat[i].length && mat[i][j + 1] == c)
					break;

				mat[i][j] = '.';
				i++;
			}

			split = false;
			len++;
		}

		if (split)
			throw new BoardFormatException("Adjacent blocks at line " + (i + 1)
					+ ", column " + (j + 1) + " (symbol " + c + ")");
		if (len < 2)
			throw new BoardFormatException("Invalid block with length " + len
					+ " at line " + (line + 1) + ", column " + (col + 1)
					+ ". Length must be at least 2.");

		return new Block(line, col, len, dir, c == '*');
	}

	/**
	 * Get the blocks sorted by their top-left corner. The contents of the char
	 * matrix is changed by this function: see
	 * {@link #getBlock(char[][], int, int)} for details.
	 */
	private static List<Block> getBlocks(char[][] mat)
			throws BoardFormatException {
		List<Block> blocks = new ArrayList<Block>();

		boolean targetFound = false;
		for (int i = 0; i < mat.length; i++) {
			for (int j = 0; j < mat[i].length; j++) {
				if (mat[i][j] == '.')
					continue;

				Block block = getBlock(mat, i, j);
				blocks.add(block);
				if (block.isTarget) {
					if (targetFound)
						throw new BoardFormatException(
								"Multiple target blocks found (extra one at line "
										+ (block.line + 1) + ", column "
										+ (block.col + 1) + ")");
					targetFound = true;
				}

				// must skip horizontal blocks, see getBlock()
				if (block.dir == Direction.HORIZONTAL)
					j += block.len - 1;
			}
		}

		if (!targetFound)
			throw new BoardFormatException("Target block missing");
		return blocks;
	}

	/**
	 * Reads a Board (and the following empty or whitespace-only line, if any)
	 * from the supplied BufferedReader. If this method were to take a Reader
	 * parameter and wrap it in a local BufferedReader, it might buffer
	 * additional unused characters which would be lost (skipped) to the caller.
	 * 
	 * @throws EOFException
	 *             if EOF reached without finding a board
	 */
	public Board(BufferedReader r) throws EOFException, IOException,
			BoardFormatException {
		char[][] mat = readMatrix(r);

		lines = mat.length;
		cols = mat[0].length;
		used = new boolean[lines][cols];
		for (int i = 0; i < mat.length; i++)
			for (int j = 0; j < mat[i].length; j++)
				used[i][j] = mat[i][j] != '.';

		blocks = getBlocks(mat);
		parent = null;
	}

	private Board(boolean[][] used, List<Block> blocks, Board parent) {
		this.used = used;
		this.blocks = blocks;
		this.lines = used.length;
		this.cols = used[0].length;
		this.parent = parent;
	}

	@Override
	public boolean equals(Object obj) {
		if (!(obj instanceof Board))
			return false;

		Board that = (Board) obj;
		return this.lines == that.lines && this.cols == that.cols
				&& this.blocks.equals(that.blocks);
	}

	@Override
	public int hashCode() {
		if (!hashCodeComputed) {
			StringBuilder sb = new StringBuilder();
			for (int i = 0; i < lines; i++)
				for (int j = 0; j < cols; j++)
					sb.append(used[i][j] ? (char) 1 : (char) 0);

			hashCode = sb.toString().hashCode();
			hashCodeComputed = true;
		}
		return hashCode;
	}

	private static boolean[][] copyMatrix(boolean[][] a) {
		boolean[][] b = new boolean[a.length][];
		for (int i = 0; i < a.length; i++)
			b[i] = Arrays.copyOf(a[i], a[i].length);
		return b;
	}

	public List<Board> getChildren() {
		try {
			List<Board> children = new ArrayList<Board>();

			for (int pos = 0; pos < blocks.size(); pos++) {
				Block block = blocks.get(pos);
				final int inc_line, inc_col;
				if (block.dir == Direction.HORIZONTAL) {
					inc_line = 0;
					inc_col = 1;
				} else {
					inc_line = 1;
					inc_col = 0;
				}

				boolean[][] used = copyMatrix(this.used);
				// 2 sentinels: before the first cell and after the last
				int s_before_l = block.line - inc_line;
				int s_before_c = block.col - inc_col;
				int s_after_l = block.line + block.len * inc_line;
				int s_after_c = block.col + block.len * inc_col;

				// move block to left (for horiz) or up (for vert)
				while (s_before_l >= 0 && s_before_c >= 0
						&& !used[s_before_l][s_before_c]) {
					Block newBlock = new Block(s_before_l, s_before_c,
							block.len, block.dir, block.isTarget);

					used[s_before_l][s_before_c] = true;
					s_before_l -= inc_line;
					s_before_c -= inc_col;

					s_after_l -= inc_line;
					s_after_c -= inc_col;
					used[s_after_l][s_after_c] = false;

					List<Block> childBlocks = new ArrayList<Block>(blocks);
					childBlocks.set(pos, newBlock);

					if (block.dir == Direction.VERTICAL) {
						// the block list must be sorted (by top-left corner)
						childBlocks.remove(pos);
						int insertion_point = -(Collections.binarySearch(
								childBlocks, newBlock, Block.topLeftComparator) + 1);
						childBlocks.add(insertion_point, newBlock);
					}

					boolean[][] childMat = copyMatrix(used);
					children.add(new Board(childMat, childBlocks, this));
				}

				// move block right (for horiz) or right (for vert)
				used = copyMatrix(this.used);
				s_before_l = block.line - inc_line;
				s_before_c = block.col - inc_col;
				s_after_l = block.line + block.len * inc_line;
				s_after_c = block.col + block.len * inc_col;

				while (s_after_l < lines && s_after_c < cols
						&& !used[s_after_l][s_after_c]) {
					used[s_after_l][s_after_c] = true;
					s_after_l += inc_line;
					s_after_c += inc_col;

					s_before_l += inc_line;
					s_before_c += inc_col;
					used[s_before_l][s_before_c] = false;

					Block newBlock = new Block(s_before_l + inc_line,
							s_before_c + inc_col, block.len, block.dir,
							block.isTarget);

					List<Block> childBlocks = new ArrayList<Block>(blocks);
					childBlocks.set(pos, newBlock);

					if (block.dir == Direction.VERTICAL) {
						// the block list must be sorted (by top-left corner)
						childBlocks.remove(pos);
						int insertion_point = -(Collections.binarySearch(
								childBlocks, newBlock, Block.topLeftComparator) + 1);
						childBlocks.add(insertion_point, newBlock);
					}

					boolean[][] childMat = copyMatrix(used);
					children.add(new Board(childMat, childBlocks, this));
				}
			}

			return children;
		} catch (BoardFormatException e) {
			throw new RuntimeException(e);
		}
	}

	public boolean isSolution() {
		for (Block b : blocks) {
			if (b.isTarget && b.col + b.len == cols)
				return true;
		}

		return false;
	}

	/** Symbols used for blocks when printing the board */
	static private final char[] blockSymbols;
	static {
		StringBuilder sb = new StringBuilder();
		for (char c = 'A'; c <= 'Z'; c++)
			sb.append(c);
		for (char c = 'a'; c <= 'z'; c++)
			sb.append(c);
		for (char c = '0'; c <= '9'; c++)
			sb.append(c);
		blockSymbols = sb.toString().toCharArray();
	}

	@Override
	public String toString() {
		// To keep things simple, if block i is target then the i-th symbol will
		// be skipped
		if (blocks.size() > blockSymbols.length)
			throw new RuntimeException("Board has more blocks ("
					+ blocks.size() + ") than unique valid symbols ("
					+ blockSymbols.length + ").\nUpgrade the print algorithm "
					+ "to re-use symbols for non-adjacent blocks.");

		char[][] mat = new char[lines][cols];
		for (int i = 0; i < lines; i++)
			for (int j = 0; j < cols; j++)
				mat[i][j] = '.';

		for (int pos = 0; pos < blocks.size(); pos++) {
			Block b = blocks.get(pos);
			char c = b.isTarget ? '*' : blockSymbols[pos];

			int line = b.line, col = b.col;
			final int inc_line, inc_col;
			if (b.dir == Direction.HORIZONTAL) {
				inc_line = 0;
				inc_col = 1;
			} else {
				inc_line = 1;
				inc_col = 0;
			}

			for (int i = 0; i < b.len; i++) {
				mat[line][col] = c;
				line += inc_line;
				col += inc_col;
			}
		}

		StringBuilder sb = new StringBuilder();
		for (char[] mat_line : mat) {
			sb.append(mat_line);
			sb.append('\n');
		}
		return sb.toString();
	}

}
