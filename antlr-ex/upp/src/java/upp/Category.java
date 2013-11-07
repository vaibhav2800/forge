package upp;

import java.util.LinkedList;
import java.util.List;

public class Category {

	public final String name;
	public final List<Item> items = new LinkedList<Item>();

	Category(String name) {
		this.name = name;
	}

}
