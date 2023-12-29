import funkin.editors.ui.UIState;

function update(elapsed:Float)
	if (FlxG.keys.justPressed.G)
		FlxG.switchState(new UIState(true, 'XMLUIState'));