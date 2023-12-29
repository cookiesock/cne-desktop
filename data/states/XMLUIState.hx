import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UITopMenu;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIState;
import haxe.Xml;

public var folderName:String = 'default';
public var uiPath:String = 'ui/';
public var xml:Xml;

public var uiMap:Map<String, FlxSprite> = [];

var dontContinue:Bool = false;
function create() {
	if (Assets.exists(Paths.xml(uiPath + folderName + '/main')))
		xml = Xml.parse(Assets.getText(Paths.xml(uiPath + folderName + '/main'))).firstElement();
	else {
		trace('your xml doesnt exist (path is supposed to be ' + uiPath + folderName + '/main.xml)');
		
		if (Assets.exists(Paths.xml(uiPath + 'default/main'))) {
			trace('using ' + uiPath + 'default.xml as fallback');
			xml = Xml.parse(Assets.getText(Paths.xml(uiPath + 'default/main'))).firstElement();
		} else
			dontContinue = true;
	}
	
	if (dontContinue) return;
	
	var script = Script.create(Paths.script('data/' + uiPath + folderName + '/main'));
	if (!(script is DummyScript)) {
		stateScripts.add(script);
		script.load();
	}

	if (xml.exists('color'))
		FlxG.camera.bgColor = FlxColor.fromString(xml.get('color'));

	for (element in xml.elements())
		sprFromNode(element);
}

function load(name:String) {
	trace('ass');
}

function sprFromNode(node:Xml):FlxSprite {
	var cancelled:Bool = false;
	call('onNodeParse', [{
		node: node,
		cancel: function() {cancelled = true;}
	}]);

	if (cancelled) return;
	
	if (!node.exists('name')) {
		trace('node ' + node.nodeName + ' has no field "name"');
		return;
	}

	var spr:FlxSprite;
	if (node.nodeName != 'topmenu') {
		switch(node.nodeName) {
			case 'checkbox':
				spr = new UICheckbox(
					node.exists('x') ? Std.parseFloat(node.get('x')) : 0,
					node.exists('y') ? Std.parseFloat(node.get('y')) : 0,
					node.exists('text') ? node.get('text') : 'Checkbox',
					node.exists('checked') ? node.get('checked') == 'true' : false,
					node.exists('width') ? Std.parseInt(node.get('width')) : 0
				);

				if (node.exists('callback'))
					spr.onChecked = () -> {
						call(node.get('callback'), [spr]);
					};
			case 'button':
				spr = new UIButton(
					node.exists('x') ? Std.parseFloat(node.get('x')) : 0,
					node.exists('y') ? Std.parseFloat(node.get('y')) : 0,
					node.exists('text') ? node.get('text') : 'Button',
					() -> {
						if (node.exists('callback')) 
							call(node.get('callback'), [spr]);
					},
					node.exists('width') ? Std.parseInt(node.get('width')) : 120,
					node.exists('height') ? Std.parseInt(node.get('height')) : 32
				);
		}
	} else {
		var options = [];
		for (element in node.elementsNamed('option')) {
			options.push({
				label: element.exists('label') ? element.get('label') : 'Label',
				childs: [for (child in element.elementsNamed('child')) {
					var ass = {
						label: child.exists('label') ? child.get('label') : 'child',
						closeOnSelect: child.exists('closeonselect') ? child.get('closeonselect') == 'true' : null,
						color: child.exists('color') ? FlxColor.fromString(child.get('color')) : null,
						icon: child.exists('icon') ? Std.parseInt(child.get('icon')) : null,
						onSelect: child.exists('onselect') ? (opt) -> {
							call(child.get('onselect', [opt]));
						} : null,
						onCreate: child.exists('oncreate') ? (opt) -> {
							call(child.get('oncreate', [opt]));
						} : null
					};
					ass;
				}]
			});
		}

		spr = new UITopMenu(options);
	}
	
	add(spr);
	uiMap.set(node.get('name'), spr);

	call('onPostNodeParse', [{
		node: node
	}]);
}

function update(elapsed:Float) {
	if (FlxG.keys.justPressed.EIGHT)
		FlxG.switchState(new UIState(true, 'XMLUIState'));
}