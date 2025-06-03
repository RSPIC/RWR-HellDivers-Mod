#include "path://media/packages/vanilla/scripts"
// --------------------------------------------
// TODO: replace with your package's script folder here
// --------------------------------------------
#include "path://media/packages/hell_diver/scripts"

#include "my_gamemode.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;
	settings.fromXmlElement(inputSettings);
	_setupLog(inputSettings);
	settings.print();
	settings.m_xpFactor = 2;
	settings.m_rpFactor = 1;
	settings.m_server_difficulty_level = 9;
	settings.m_initialRp = 10000.0;
	settings.m_initialXp = 0.0;
	settings.m_server_test_mode = true;
	settings.m_debug_mode = false;
	settings.m_single_player = true;
	settings.m_fov = false;

	// --------------------------------------------
	// TODO: replace with your package's folder here
	// --------------------------------------------
	array<string> overlays = {
                "media/packages/hell_diver"
        };
    //settings.m_overlayPaths = overlays;
	settings.m_startServerCommand = """
	<command class='start_server'
		server_name='[HellDicer] SinglePlayer Champion'
		server_port='1245'
		url='https://steamcommunity.com/sharedfiles/filedetails/?id=2910392031'
		register_in_serverlist='0'
		mode='HD'
		persistency='forever'
		comment='Helldiver SinglePlayer'
		max_players='16'>
		<client_faction id='0' />
	</command>
	""";
	_log("init Metagame Start");
	MyGameMode metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
