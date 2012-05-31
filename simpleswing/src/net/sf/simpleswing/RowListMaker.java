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
import java.awt.Insets;

/**
 * Adds rows of Components to a Container.
 */
public class RowListMaker extends GridBagContainerFiller {

	private GridBagConstraints c = new GridBagConstraints();

	/**
	 * Constructor taking the Container to fill with rows of Components.
	 * 
	 * @param contToFill
	 *            The Container to fill with Components
	 */
	public RowListMaker(Container contToFill) {
		super(contToFill);
		c.gridx = 0;
	}

	/**
	 * Adds a row of Components, left-aligned.
	 * 
	 * @param components
	 *            the Components to add
	 */
	public void addLine(Component... components) {
		addLine(GridBagConstraints.LINE_START, 0, components);
	}

	/**
	 * Adds a row of Components, centered.
	 * 
	 * @param components
	 *            the Components to add
	 */
	public void addLineCenter(Component... components) {
		addLine(GridBagConstraints.CENTER, 0, components);
	}

	/**
	 * Adds a row of Components, left-aligned and indented by
	 * {@link GridBagContainerFiller#indentSize}.
	 * 
	 * @param components
	 *            the Components to add
	 */
	public void addIndentedLine(Component... components) {
		addLine(GridBagConstraints.LINE_START, indentSize, components);
	}

	/**
	 * Adds a row of Components, aligned according to <code>anchor</code> and
	 * optionally indented by the specified amount. If a single Component is
	 * added, a spacing of {@link #spacedInsets} is used. Otherwise the
	 * components are placed inside a JPanel using
	 * {@link #makeRowContainer(Component...)} which is then added using no
	 * additional spacing {@link #zeroInsets}.
	 * 
	 * @param anchor
	 *            the anchor (e.g. GridBagConstraints.LINE_START)
	 * @param extraIndent
	 *            indent amount (e.g. {@link GridBagContainerFiller#indentSize})
	 * @param components
	 *            the Components to add
	 */
	public void addLine(int anchor, int extraIndent, Component... components) {
		if (components.length == 0)
			return;

		Component crtLine;
		if (components.length == 1) {
			crtLine = components[0];
			c.insets = spacedInsets;
		} else {
			crtLine = makeRowContainer(components);
			c.insets = zeroInsets;
		}

		if (extraIndent != 0) {
			c.insets = (Insets) c.insets.clone();
			c.insets.left += extraIndent;
		}
		c.anchor = anchor;
		c.gridy = skipLine();
		container.add(crtLine, c);
	}

	/**
	 * Add a single Component on a row, left aligned (to
	 * <code>GridBagConstraints.LINE_START</code>) using zero Insets
	 * {@link #zeroInsets}. This may be desired when adding a single Container
	 * whose elements need no additional spacing (the
	 * {@link #addLine(int, int, Component...)} method uses
	 * {@link #spacedInsets} when adding a single Component to a row).
	 * 
	 * @param component
	 *            the component to add
	 */
	public void addSingleCompZeroInsets(Component component) {
		c.insets = zeroInsets;

		c.anchor = GridBagConstraints.LINE_START;
		c.gridy = skipLine();
		container.add(component, c);
	}

	@Override
	public void addFillComponent(Component component) {
		GridBagConstraints cFill = getFillConstraints(0, skipLine());
		container.add(component, cFill);
	}

	@Override
	public void addFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getFillConstraints(0, skipLine());
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

	@Override
	public void addHorizFillComponent(Component component) {
		GridBagConstraints cFill = getHorizFillConstraints(0, skipLine());
		container.add(component, cFill);
	}

	@Override
	public void addHorizFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getHorizFillConstraints(0, skipLine());
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

	@Override
	public void addVertFillComponent(Component component) {
		GridBagConstraints cFill = getVertFillConstraints(0, skipLine());
		container.add(component, cFill);
	}

	@Override
	public void addVertFillComponentZeroInsets(Component component) {
		GridBagConstraints cFill = getVertFillConstraints(0, skipLine());
		cFill.insets = zeroInsets;
		container.add(component, cFill);
	}

}
