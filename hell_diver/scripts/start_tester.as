#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"
#include "gamemode_tester.as"

void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	GameModeTester metagame(inputSettings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}