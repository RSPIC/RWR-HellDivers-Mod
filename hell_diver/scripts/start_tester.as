// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;
        settings.fromXmlElement(inputSettings);
		
        _setupLog("dev_verbose");

        settings.m_factionChoice = 0;
        array<string> overlays = {
                "media/packages/hell_diver"
        };
        // settings.m_overlayPaths = overlays;

        settings.print();

        GameModeInvasion metagame(settings);

        metagame.init();
        metagame.run();
        metagame.uninit();

        _log("ending execution");
}



