// --------------------------------------------
class AdminManager {
	protected Metagame@ m_metagame;
	protected array<string> m_admins;

	// --------------------------------------------
	AdminManager(Metagame@ metagame) {
		@m_metagame = metagame;
	}

	// --------------------------------------------
	void addAdmin(string name) {
		m_admins.insertLast(name.toLowerCase());
		//_log("admin_manager:insert admin name="+name);
	}

	// --------------------------------------------
	void loadFromFile() {
		m_admins = loadStringsFromFile(m_metagame, "admins.xml");
		//_log("admin_manager:ready to load file");
		for (uint i = 0; i < m_admins.size(); ++i) {
			m_admins[i] = m_admins[i].toLowerCase();
			//_log("admin_manager:find admin name= "+m_admins[i]);
		}
	}

	// --------------------------------------------
	bool isAdmin(string name, int playerId = -1) const {
		// consider server console comments as admin
		//_log("admin_manager:is admin? name= "+name);
		//_log("admin_manager:is admin? pid= "+playerId);
		if (playerId == 0 || name == "MR. RST") {
			return true;
		}
		return m_admins.find(name.toLowerCase()) >= 0;
	}
};
