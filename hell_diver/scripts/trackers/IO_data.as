#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"

#include "debug_reporter.as"
#include "INFO.as"

const XmlElement@ readXML(const Metagame@ metagame, string filename){
	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "saved_data"}, {"filename", filename}, {"location", "app_data"} } }));
	const XmlElement@ xml = metagame.getComms().query(query).getFirstChild();
	return xml;
}

void writeXML(const Metagame@ metagame, string filename, XmlElement@ xml, string location = "app_data" ){
	XmlElement command("command");
		command.setStringAttribute("class", "save_data");
		command.setStringAttribute("filename", filename);
		command.setStringAttribute("location", location);
		command.appendChild(xml);
	metagame.getComms().send(command);
}

class IO_data : Tracker {
    protected Metagame@ m_metagame;
    protected bool save_data;
    protected float m_time;
    protected float m_timer;


    IO_data(Metagame@ metagame){
        @m_metagame = @metagame;
        m_time = 1.0;
        m_timer = m_time;
        save_data = false;
    }
    // --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;
        if(m_timer <= 0.0){
            m_timer = m_time;
        }
        if(save_data){
            save();
        }
    }
    // -------------------------------------------
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		string p_name = event.getStringAttribute("player_name");
		if(m_metagame.getAdminManager().isAdmin(p_name)){
			if(message == "/save"){
				save_data = true;
			}
			if(message == "/read"){
				read();
			}

		}
	}
    protected void save(){
        XmlElement root("test");
        XmlElement xml_data("Save_data");
        xml_data.setStringAttribute("username","rst");
        xml_data.setIntAttribute("userid",114514);
        root.setStringAttribute("username","abc");
        root.setIntAttribute("userid",11234);
        xml_data.appendChild(root);

        writeXML(m_metagame,"save_data_test.xml",xml_data);
        _report(m_metagame,"save_data");
        save_data=false;
    }
    protected void read(){
        const XmlElement@ root = readXML(m_metagame,"save_data_test.xml").getFirstChild();
        _report(m_metagame,"read data");
        array<const XmlElement@> info = root.getElementsByTagName("test");
        _report(m_metagame,"info size="+info.size());
        _report(m_metagame,"root ="+root.toString());
        for(uint i=0;i < info.size(); ++i){
            const XmlElement@ a = info[i];
            string name = a.getStringAttribute("username");
            int id = a.getIntAttribute("userid");
            _report(m_metagame,"username = "+name);
            _report(m_metagame,"ID = "+id);
        }
    }
}