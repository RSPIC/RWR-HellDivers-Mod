#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/edelweiss/scripts"
#include "path://media/packages/ww2_undead/scripts"

#include "my_gamemode.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);
	
    array<string> overlays = {
            "media/packages/ww2_base"
    };
	
	UserSettings settings;
    settings.m_overlayPaths = overlays;

    settings.m_startServerCommand = """
<command class='start_server'
	server_name='Ww2UndeadTest'
	server_port='1240'
	comment='Coop campaign'
	url=''
	register_in_serverlist='1'
	mode='COOP'
	persistency='forever'
	max_players='24'>
	<client_faction id='0' />
</command>
""";

	settings.m_journalEnabled = true;

	// TODO: to be disabled before release
	settings.m_testingToolsEnabled = true;

	settings.fromXmlElement(inputSettings);
	
	settings.m_initialRp = 450;  
	settings.m_initialXp = 0.0;
	settings.m_fellowCapacityFactor = 1.0;
	settings.m_fellowAiAccuracyFactor = 0.94;
	settings.m_enemyCapacityFactor = 1.0;
	settings.m_enemyAiAccuracyFactor = 0.90;
	settings.m_xpFactor = 0.5;
	settings.m_rpFactor = 1.0;
	settings.m_playerDamageModifier = 0.15;
	
	_setupLog(inputSettings);
	settings.print();

	MyGameMode metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
