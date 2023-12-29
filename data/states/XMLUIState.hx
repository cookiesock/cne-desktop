import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UITopMenu;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIState;
import haxe.Xml;

public var folderName:String = 'example';
public var uiPath:String = 'ui/';
public var curPath:String = uiPath + folderName + '/main';
public var xml:Xml;
public var spriteMap:Map<String, FlxSprite> = [];
public var script:Script;
var dontContinue:Bool = false;

function create()
	load(curPath);

function load(path:String) {
	var theThing:String = path;
	call('onLoad', [{
		path: path,
		changePath: function(value:String) {
			theThing = value;
		}
	}]);
	curPath = path = theThing;
	closeSubState();

	for (name=>sprite in spriteMap) {
		remove(sprite);
		spriteMap.remove(name);
	}
	xml = null;
	if (script != null)
		stateScripts.remove(script);
	script = null;

	if (Assets.exists(Paths.xml(path)))
		xml = Xml.parse(Assets.getText(Paths.xml(path))).firstElement();
	else {
		trace('your xml doesnt exist (path is supposed to be ' + path + '/main.xml)');
		
		if (Assets.exists(Paths.xml(uiPath + 'example/main'))) {
			trace('using ' + uiPath + 'example/main.xml as fallback');
			xml = Xml.parse(Assets.getText(Paths.xml(uiPath + 'example/main'))).firstElement();
		} else
			dontContinue = true;
	}
	
	if (dontContinue) return;
	
	script = Script.create(Paths.script('data/' + path));
	if (!(script is DummyScript)) {
		stateScripts.add(script);
		script.load();
	}

	if (xml.exists('color'))
		FlxG.camera.bgColor = FlxColor.fromString(xml.get('color'));

	for (element in xml.elements())
		sprFromNode(element);

	call('onPostLoad', [{
		path: path
	}]);
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
						if (node.exists('goto'))
							load(uiPath + folderName + node.get('goto'));
						else if (node.exists('callback')) 
							call(node.get('callback'), [spr]);
					},
					node.exists('width') ? Std.parseInt(node.get('width')) : 120,
					node.exists('height') ? Std.parseInt(node.get('height')) : 32
				);
			case 'dropdown':
				spr = new UIDropDown(
					node.exists('x') ? Std.parseFloat(node.get('x')) : 0,
					node.exists('y') ? Std.parseFloat(node.get('y')) : 0,
					node.exists('width') ? Std.parseInt(node.get('width')) : 320,
					node.exists('height') ? Std.parseInt(node.get('height')) : 32,
					node.exists('options') ? node.get('options').split(',') : [],
					node.exists('index') ? Std.parseInt(node.get('index')) : 0
				);

				if (node.exists('onchange'))
					spr.onChange = (value) -> {
						call(node.get('onchange'), [value, spr]);
					};
		}
	} else {
		spr = new UITopMenu([for (element in node.elementsNamed('option')) {
			var stupid = {
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
			};
			stupid;
		}]);
	}
	
	add(spr);
	spriteMap.set(node.get('name'), spr);
	stateScripts.set(node.get('name'), spr);

	call('onPostNodeParse', [{
		node: node
	}]);
}

function update(elapsed:Float) {
	if (FlxG.keys.justPressed.EIGHT)
		FlxG.switchState(new UIState(true, 'XMLUIState'));

	if (FlxG.keys.justPressed.F4) // refresh
		load(curPath);
}