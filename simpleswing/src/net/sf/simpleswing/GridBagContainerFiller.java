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

import java.awt.Component;
import java.awt.Container;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;

import javax.swing.JPanel;

/**
 * Abstract superclass for classes used to fill a container with components
 * using (mostly) a <code>GridBagLayout</code>. This class provides some common
 * utility methods. The <em>lines</em> of a GridBagContainerFiller may be either
 * rows or columns, depending on the particular implementing subclass.
 */
public abstract class GridBagContainerFiller {

	/**
	 * The Container to be filled by this object.
	 */
	public final Container container;

	/**
	 * The next grid line to be filled
	 */
	private int gridLine;

	/**
	 * Default spacing for components: <code>new Insets(2, 2, 2, 2)</code>.
	 */
	protected static final Insets spacedInsets = new Insets(2, 2, 2, 2);

	/**
	 * Equal to <code>new Insets(0, 0, 0, 0)</code> and used by the
	 * *ZeroInsets() methods. Desirable when the component to add is a container
	 * whose elements are already spaced and no additional spacing is desired.
	 */
	protected static Insets zeroInsets = new Insets(0, 0, 0, 0);

	/**
	 * Indent size for some user-chosen rows of components: <code>30</code>.
	 */
	protected static int indentSize = 30;

	/**
	 * Constructor requiring a Container to be filled by the subclasses, by
	 * repeatedly invoking methods to add Components to it.
	 * 
	 * @param contToFill
	 *            The Container to be filled
	 */
	GridBagContainerFiller(Container contToFill) {
		container = contToFill;
		container.setLayout(new GridBagLayout());
	}

	/**
	 * Skips a Container line (so its components can be added manually to the
	 * Container's GridBagLayout) and returns the skipped line's zero-based
	 * index.
	 * 
	 * @return The skipped line's zero-based index
	 */
	protected int skipLine() {
		return gridLine++;
	}

	/**
	 * Puts the components inside a JPanel on a single row using a
	 * {@link RowMaker} and default spacing ({@link #spacedInsets}).
	 * 
	 * @param components
	 *            The components to put inside the JPanel on a single row
	 * @return The resulting JPanel
	 */
	protected static JPanel makeRowContainer(Component... components) {
		JPanel p = new JPanel();
		// p.setBorder(javax.swing.BorderFactory.createTitledBorder("Made up"));
		RowMaker rm = new RowMaker(p);
		rm.addComponents(components);
		return p;
	}

	/**
	 * Creates the <code>GridBagConstraints</code> needed by a
	 * <code>Component</code> to fill the specified cell of a GridBagLayout both
	 * horizontally and vertically (using default spacing of
	 * {@link #spacedInsets}). By changing the <code>gridwidth</code> or
	 * <code>gridheight</code> fields of the returned object to
	 * <code>GridBagConstraints.REMAINDER</code>, the <code>Component</code> to
	 * add can fill the rest of its row or column, respectively.
	 * 
	 * @param gridx
	 *            the zero-based column
	 * @param gridy
	 *            the zero-based row
	 * @return the GridBagConstraints for filling the specified grid cell
	 */
	protected static GridBagConstraints getFillConstraints(int gridx, int gridy) {
		GridBagConstraints c = new GridBagConstraints();
		c.gridx = gridx;
		c.gridy = gridy;
		c.fill = GridBagConstraints.BOTH;
		c.weightx = 1.0;
		c.weighty = 1.0;
		c.insets = spacedInsets;
		return c;
	}

	/**
	 * Creates the <code>GridBagConstraints</code> needed by a
	 * <code>Component</code> to horizontally fill the specified cell of a
	 * GridBagLayout (using default spacing of {@link #spacedInsets}).
	 * 
	 * @param gridx
	 *            the zero-based column
	 * @param gridy
	 *            the zero-based row
	 * @return the GridBagConstraints for filling the specified grid cell
	 *         horizontally
	 */
	protected static GridBagConstraints getHorizFillConstraints(int gridx,
			int gridy) {
		GridBagConstraints c = new GridBagConstraints();
		c.gridx = gridx;
		c.gridy = gridy;
		c.fill = GridBagConstraints.HORIZONTAL;
		c.weightx = 1.0;
		c.insets = spacedInsets;
		return c;
	}

	/**
	 * Creates the <code>GridBagConstraints</code> needed by a
	 * <code>Component</code> to vertically fill the specified cell of a
	 * GridBagLayout (using default spacing of {@link #spacedInsets}).
	 * 
	 * @param gridx
	 *            the zero-based column
	 * @param gridy
	 *            the zero-based row
	 * @return the GridBagConstraints for filling the specified grid cell
	 *         vertically
	 */
	protected static GridBagConstraints getVertFillConstraints(int gridx,
			int gridy) {
		GridBagConstraints c = new GridBagConstraints();
		c.gridx = gridx;
		c.gridy = gridy;
		c.fill = GridBagConstraints.VERTICAL;
		c.weighty = 1.0;
		c.insets = spacedInsets;
		return c;
	}

	/**
	 * Returns a new JPanel containing <code>innerComponent</code> aligned to
	 * the top and filling it horizontally using zero spacing
	 * {@link #zeroInsets}.
	 * 
	 * @param innerComponent
	 *            the component to be held inside the JPanel
	 * @return the newly created JPanel
	 */
	public static JPanel makeTopHorizFillHolder(Component innerComponent) {
		JPanel p = new JPanel();
		makeTopHorizFillHolder(innerComponent, p);
		return p;
	}

	/**
	 * Places <code>innerComponent</code> inside <code>holder</code> aligned to
	 * the top and filling it horizontally using zero spacing
	 * {@link #zeroInsets}.
	 * 
	 * @param innerComponent
	 *            the Component to hold
	 * @param holder
	 *            the holding Container
	 */
	public static void makeTopHorizFillHolder(Component innerComponent,
			Container holder) {
		holder.setLayout(new GridBagLayout());
		GridBagConstraints c = new GridBagConstraints();
		c.gridx = c.gridy = 0;

		// the cell needs to stretch both horizontally and vertically
		// otherwise it gets put in the middle of the holder
		c.weightx = c.weighty = 1.0;

		// the contents (innerComponent) only stretches horizontally
		c.fill = GridBagConstraints.HORIZONTAL;
		c.anchor = GridBagConstraints.PAGE_START;
		holder.add(innerComponent, c);
	}

	/**
	 * Returns a new JPanel containing <code>innerComponent</code> aligned to
	 * the top left using zero spacing {@link #zeroInsets}.
	 * 
	 * @param innerComponent
	 *            the component to be held inside the JPanel
	 * @return the newly created JPanel
	 */
	public static JPanel makeTopLeftHolder(Component innerComponent) {
		JPanel p = new JPanel();
		makeTopLeftHolder(innerComponent, p);
		return p;
	}

	/**
	 * Places <code>innerComponent</code> inside <code>holder</code> aligned to
	 * the top left using zero spacing {@link #zeroInsets}.
	 * 
	 * @param innerComponent
	 *            the Component to hold
	 * @param holder
	 *            the holding Container
	 */
	public static void makeTopLeftHolder(Component innerComponent,
			Container holder) {
		holder.setLayout(new GridBagLayout());
		GridBagConstraints c = new GridBagConstraints();
		c.gridx = c.gridy = 0;

		// the cell needs to stretch both horizontally and vertically
		// otherwise it gets put in the middle of the holder
		c.weightx = c.weighty = 1.0;

		c.anchor = GridBagConstraints.FIRST_LINE_START;
		holder.add(innerComponent, c);
	}

	// The *zeroInsets methods below could be changed to take an Insets
	// parameter if more generality is needed

	/**
	 * Adds a single Component filling the next line of the Container
	 * horizontally and vertically using default spacing {@link #spacedInsets}.
	 * 
	 * @param component
	 *            the Component to add
	 */
	public abstract void addFillComponent(Component component);

	/**
	 * Adds a single Component filling the next line of the Container
	 * horizontally and vertically using zero spacing {@link #zeroInsets}.
	 * 
	 * @param component
	 *            the Component to add
	 */
	public abstract void addFillComponentZeroInsets(Component component);

	/**
	 * Adds a single Component filling the next line of the Container
	 * horizontally using default spacing {@link #spacedInsets}.
	 * 
	 * @param component
	 *            the Component to add
	 */
	public abstract void addHorizFillComponent(Component component);

	/**
	 * Adds a single Component filling the next line of the Container
	 * horizontally using zero spacing {@link #zeroInsets}.
	 * 
	 * @param component
	 *            the Component to add
	 */
	public abstract void addHorizFillComponentZeroInsets(Component component);

	/**
	 * Adds a single Component filling the next line of the Container vertically
	 * using default spacing {@link #spacedInsets}.
	 * 
	 * @param component
	 *            the Component to add
	 */
	public abstract void addVertFillComponent(Component component);

	/**
	 * Adds a single Component filling the next line of the Container vertically
	 * using zero spacing {@link #zeroInsets}.
	 * 
	 * @param component
	 *            the Component to add
	 */
	public abstract void addVertFillComponentZeroInsets(Component component);

}
