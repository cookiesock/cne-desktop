function onPostLoad() {
	trace('ass');

	trace(buttonThing.x, buttonThing.y);
}

function childFunc() {
	trace('child func called');
}

function childFunc2() {
	trace('child func 2 called');
}

function checkFunc() {
	trace('checkbox func called');
}

function testFunc() {
	trace('test func called');
}

function exitFunc()
	FlxG.switchState(new MainMenuState());