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
import java.util.Arrays;

/**
 * Adds GUI objects to a Container in a form-like fashion. The elements are
 * added line by line. Each line may contain one or more Components.
 * <p>
 * The first component in a row is usually a label, aligned to the right. The
 * second one is usually an input field, aligned to the left. If the row has a
 * single component, it is aligned according to user preference, or to the left
 * by default. If it has more than two components, the first is aligned to the
 * right in the first column and the others are put inside a JPanel (if they are
 * more than one) then aligned to the left in the second column.
 * <p>
 * All components are added using default spacing of {@link #spacedInsets} with
 * one exception: If more than 2 components are added in the same row,
 * components 2..n are placed inside a JPanel using {@link #makeRowContainer}
 * and this JPanel is placed in the second column using no additional spacing:
 * {@link #zeroInsets}.
 */
public class FormMaker extends GridBagContainerFiller {

	/**
	 * Constructs a new FormMaker which will populate the specified Container.
	 * 
	 * @param contToFill
	 *            the container to be populated by this FormMaker object
	 */
	public FormMaker(Container contToFill) {
		super(contToFill);
	}

	/**
	 * Adds a line of Components to the Container populated by this FormMaker
	 * using default alignment. Equivalent to calling
	 * {@link #addFormLine(int, Component...)} with a
	 * <code>singleComponentAnchor</code> argument of
	 * <code>GridBagConstraints.LINE_START</code> (if the argument is a single
	 * Component, it will be left-aligned).
	 * 
	 * @param components
	 *            Components to be added on a line
	 */
	public void addFormLine(Component... components) {
		addFormLine(GridBagConstraints.LINE_START, components);
	}

	/**
	 * Adds a center-aligned component alone on a line. Equivalent to calling
	 * {@link #addFormLine(int, Component...)} with a
	 * <code>singleComponentAnchor</code> argument of
	 * <code>GridBagConstraints.CENTER</code>.
	 * 
	 * @param component
	 *            the component to add
	 */
	public void addSingleCompCenter(Component component) {
		addFormLine(GridBagConstraints.CENTER, component);
	}

	/**
	 * Adds a row of Components using default (form-like) alignment. If adding a
	 * single component, it is aligned according to
	 * <code>singleComponentAnchor</code>. Otherwise the first component is
	 * right-aligned in the first column and the others are left-aligned in the
	 * second column (after putting then in a JPanel using
	 * {@link #makeRowContainer} if they are more than 1; in this case, the
	 * JPanel is added to its column using no additional spacing:
	 * {@link #zeroInsets}).
	 * 
	 * @param singleComponentAnchor
	 *            the anchor to use if a single Component is being added
	 * @param components
	 *            the components to add
	 */
	public void addFormLine(int singleComponentAnchor, Component... components) {
		if (components.length == 0)
			return;

		int gridy = skipLine();

		GridBagConstraints c = new GridBagConstraints();
		c.insets = spacedInsets;
		c.gridy = gridy;
		c.gridx = 0;

		// add first component
		if (components.length == 1) {
			c.gridwidth = 2;
			c.anchor = singleComponentAnchor;
		} else {
			c.anchor = GridBagConstraints.LINE_END;
		}
		container.add(components[0], c);

		if (components.length == 1)
			return;

		// add the other components
		c = new GridBagConstraints();
		c.insets = spacedInsets;
		c.gridy = gridy;
		c.gridx = 1;
		c.anchor = GridBagConstraints.LINE_START;
		Component comp2;

		if (components.length == 2) {
			comp2 = components[1];
		} else {
			comp2 = makeRowContainer(Arrays.copyOfRange(components, 1,
					components.length));
			c.insets = zeroInsets;
		}

		container.add(comp2, c);
	}

	@Override
	public void addFillComponent(Component component) {
		GridBagConstraints cFill = getFillConstraints(0, skipLine());
		cFill.gridwidth = GridBagConstraints.REMAINDER;
		container.add(component, cFill);
	}

	@Override
	public void addFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getFillConstraints(0, skipLine());
		cFill.gridwidth = GridBagConstraints.REMAINDER;
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

	@Override
	public void addHorizFillComponent(Component component) {
		GridBagConstraints cFill = getHorizFillConstraints(0, skipLine());
		cFill.gridwidth = GridBagConstraints.REMAINDER;
		container.add(component, cFill);
	}

	@Override
	public void addHorizFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getHorizFillConstraints(0, skipLine());
		cFill.gridwidth = GridBagConstraints.REMAINDER;
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

	@Override
	public void addVertFillComponent(Component component) {
		GridBagConstraints cFill = getVertFillConstraints(0, skipLine());
		cFill.gridwidth = GridBagConstraints.REMAINDER;
		container.add(component, cFill);
	}

	@Override
	public void addVertFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getVertFillConstraints(0, skipLine());
		cFill.gridwidth = GridBagConstraints.REMAINDER;
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

}
