#include "path://media/packages/hell_diver/scripts"
#include "path://media/packages/hell_diver_pvp/scripts"

#include "gamemode_minimodes.as"
#include "map_rotator_classic.as"

// new trackers

// --------------------------------------------
class GameModeMiniModesClassic : GameModeMiniModes {
	// --------------------------------------------
	GameModeMiniModesClassic(UserSettings@ settings) {
		super(settings);
	}

	// --------------------------------------------
	protected void setupMapRotator() {
		@m_mapRotator = MapRotatorMiniModesClassic(this);
	}
}

// --------------------------------------------
void main(dictionary@ inputData) {
	UserSettings s;
	
	s.m_timeBetweenSubstages = 40.0;
	s.m_quickmatchMaxTime = 1800.0;
	s.m_kothMaxTime = 1800.0;

	s.m_debug_mode = false;
	s.m_server_test_mode = true;

	s.m_startServerCommand = """
<command class='start_server'
        server_name='[地狱潜兵]PVP服 IP直连'
        server_port='1246'
        comment='Running with HellDivers Mod.  QQ：498520233'
        url='https://steamcommunity.com/sharedfiles/filedetails/?id=1541806712'
        register_in_serverlist='1'
	mode='HD [PVP]'
	persistency='forever_and_match'
	max_players='24'>
</command>
""";

	s.print();

	GameModeMiniModesClassic@ metagame = GameModeMiniModesClassic(s);
	
	metagame.init();
	// execution blocks here at run until comms from server is lost
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
