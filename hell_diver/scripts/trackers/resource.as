#include "helpers.as"

// --------------------------------------------
class Resource {
	string m_type;
	string m_key;

	// --------------------------------------------
	Resource(string key, string type) {
		m_key = key;
		m_type = type;
	}

    Resource(const Resource &in other) {
        m_key = other.m_key;
        m_type = other.m_type;
    }
	array<Resource@>@ multi(int num){
        array<Resource@>@ resources = array<Resource@>();
        for(;num>0;num--){
            Resource@ resource = Resource(this);
            resources.insertLast(resource);
        }
        return resources;
    }

	void addToResources(array<Resource@>@ outRes,int num){
        array<Resource@>@ inRes = multi(num);
        for(uint i=0;i<inRes.length();i++){
            outRes.insertLast(inRes[i]);
        }
    }
}

// --------------------------------------------
class ResourceChange {
	Resource@ m_resource;
	bool m_enabled;

	// --------------------------------------------
	ResourceChange(Resource@ resource, bool enabled) {
		@m_resource = @resource;
		m_enabled = enabled;
	}
};

// --------------------------------------------
XmlElement@ getFactionResourceChangeCommand(int factionId, const array<ResourceChange@>@ changes) {
	XmlElement command("command"); 
	command.setStringAttribute("class", "faction_resources"); 
	command.setIntAttribute("faction_id", factionId);

	for (uint i = 0; i < changes.size(); ++i) {
		ResourceChange@ rc = changes[i];
		addFactionResourceElements(command, rc.m_resource.m_type, array<string> = {rc.m_resource.m_key}, rc.m_enabled);
	}

	return command;
}
