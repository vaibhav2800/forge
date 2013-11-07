package see.interp;

import java.util.HashMap;
import java.util.Map;

class MemorySpace {

	public final String name;
	private Map<String, Object> members = new HashMap<String, Object>();

	MemorySpace(String name) {
		this.name = name;
	}

	void put(String id, Object obj) {
		members.put(id, obj);
	}

	Object get(String id) {
		return members.get(id);
	}

}
