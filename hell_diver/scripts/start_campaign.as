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
	settings.m_debug_mode = false;
	settings.m_xpFactor = 10;
	settings.m_rpFactor = 10;
	settings.m_server_difficulty_level = 9;
	settings.m_initialRp = 100000.0;
	settings.m_initialXp = 500.0;

	// --------------------------------------------
	// TODO: replace with your package's folder here
	// --------------------------------------------
	array<string> overlays = {
                "media/packages/hell_diver"
        };
    //settings.m_overlayPaths = overlays;

	MyGameMode metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
