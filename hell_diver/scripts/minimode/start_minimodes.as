// start scripts located elsewhere than vanilla/scripts should include
// vanilla/scripts in include path with a relative path
// e.g. set_include_path("../../../packages/vanilla/scripts"); 

// all vanilla includes are defined in relation to vanilla/scripts OR the local folder

// --------------------------------------------
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/minimodes/scripts"
#include "gamemode_minimodes.as"

// --------------------------------------------
void main(dictionary@ inputData) {

	UserSettings s;

	s.m_minimumPlayersToStart = 2;
	s.m_minimumPlayersToContinue = 2;
	s.m_timeBetweenSubstages = 20.0;

	s.m_tdmMaxTime = 900.0;
	s.m_tdmMaxScore = 5.0; // this is a "base" score, the actual max score is tdm_max_score * player_count, e.g. max_score = 3.0 * 10 = 30 

	s.m_kothMaxTime = 900.0;
	s.m_kothDefenseTime = 180.0;

	s.m_thMaxTime = 900.0;
	s.m_thMaxScore = 3;

	s.m_startServerCommand = """
<command class='start_server'
	server_name='Minimodes'
	server_port='1238'
	comment='PvP'
	url=''
	register_in_serverlist='1'
	mode='minimodes'
	persistency='match'
	max_players='24'>
	<client_faction id="0" />
	<client_faction id="1" />
</command>
""";
	
	s.print();
	
	GameModeMiniModes metagame(s);

	metagame.init();
	// execution blocks here at run until comms from server is lost
	metagame.run();
	metagame.uninit();

	_log("ending execution");

}
