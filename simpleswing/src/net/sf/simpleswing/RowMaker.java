/*
 * Copyright © Mihai Borobocea 2010
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

/**
 * Adds components to a container, on a single row, using the same spacing of
 * {@link #spacedInsets} for all components.
 */
public class RowMaker extends GridBagContainerFiller {

	private GridBagConstraints c = new GridBagConstraints();

	/**
	 * Creates a new RowMaker which will fill the specified
	 * <code>Container</code> with a row of <code>Component</code>s using
	 * {@link #spacedInsets}.
	 * 
	 * @param contToFill
	 *            the Container to populate
	 */
	public RowMaker(Container contToFill) {
		super(contToFill);
		c.gridy = 0;
		c.insets = spacedInsets;
	}

	/**
	 * Add the components, in order, to the row populated by this RowMaker. Each
	 * component will be in its own column aligned to the left
	 * <code>GridBagConstraints.LINE_START</code> by default.
	 * 
	 * @param components
	 *            the Components to add, in order, to the row
	 */
	public void addComponents(Component... components) {
		addComponents(GridBagConstraints.LINE_START, components);
	}

	/**
	 * Add the components, in order, to the row populated by this RowMaker. Each
	 * component will be in its own column aligned according to the specified
	 * <code>anchor</code>.
	 * 
	 * @param anchor
	 *            the anchor (e.g. <code>GridBagConstraints.LINE_START</code>)
	 * @param components
	 *            the Components to add, in order, to the row
	 */
	public void addComponents(int anchor, Component... components) {
		c.anchor = anchor;
		for (Component component : components) {
			c.gridx = skipLine();
			container.add(component, c);
		}
	}

	@Override
	public void addFillComponent(Component component) {
		GridBagConstraints cFill = getFillConstraints(skipLine(), 0);
		container.add(component, cFill);
	}

	@Override
	public void addFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getFillConstraints(skipLine(), 0);
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

	@Override
	public void addHorizFillComponent(Component component) {
		GridBagConstraints cFill = getHorizFillConstraints(skipLine(), 0);
		container.add(component, cFill);
	}

	@Override
	public void addHorizFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getHorizFillConstraints(skipLine(), 0);
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

	@Override
	public void addVertFillComponent(Component component) {
		GridBagConstraints cFill = getVertFillConstraints(skipLine(), 0);
		container.add(component, cFill);
	}

	@Override
	public void addVertFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getVertFillConstraints(skipLine(), 0);
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

}
