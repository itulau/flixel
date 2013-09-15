package;

import flixel.effects.particles.FlxEmitter;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.util.FlxPoint;
import openfl.Assets;

class PlayState extends FlxState
{
	public var map:FlxTilemap;
	public var background:FlxTilemap;
	public var ladders:FlxTilemap;
	public var player:Player;

	private var _gibs:FlxEmitter;
	private var _mongibs:FlxEmitter;
	private var _bullets:FlxGroup;
	private var _badbullets:FlxGroup;
	private var _restart:Bool;
	private var _text1:FlxText;
	private var _enemies:FlxGroup;
	private var _coins:FlxGroup;
	private var _score:FlxText;
	
	override public function create():Void
	{
		map = new FlxTilemap();
		map.allowCollisions = FlxObject.ANY;
		background = new FlxTilemap();
		ladders = new FlxTilemap();
		
		_restart = false;
		
		add(background.loadMap(Assets.getText("assets/levels/mapCSV_Group1_Map1back.csv"), "assets/art/area02_level_tiles2.png", 16, 16, FlxTilemap.OFF));
		background.scrollFactor.x = background.scrollFactor.y = .5;
		
		add(map.loadMap(Assets.getText("assets/levels/mapCSV_Group1_Map1.csv"), "assets/art/area02_level_tiles2.png", 16, 16));
		add(ladders.loadMap(Assets.getText("assets/levels/mapCSV_Group1_Ladders.csv"), "assets/art/area02_level_tiles2.png", 16, 16));
		
		FlxG.camera.setBounds(0, 0, map.width, map.height);
		FlxG.worldBounds.set(0, 0, map.width, map.height);
		
		// Set up the gibs
		_gibs = new FlxEmitter();
		_gibs.setXSpeed( -150, 150);
		_gibs.setYSpeed( -200, 0);
		_gibs.setRotation( -720, 720);
		_gibs.makeParticles("assets/art/lizgibs.png", 25, 16, true, .5);
		
		_mongibs = new FlxEmitter();
		_mongibs.setXSpeed( -150, 150);
		_mongibs.setYSpeed( -200, 0);
		_mongibs.setRotation( -720, 720);
		_mongibs.makeParticles("assets/art/spikegibs.png", 25, 16, true, .5);
		
		// Create the actual group of bullets here
		_bullets = new FlxGroup();
		_bullets.maxSize = 4;
		_badbullets = new FlxGroup();
		
		add(player = new Player(112, 92, this, _gibs, _bullets));
		
		// Attach the camera to the player. The number is how much to lag the camera to smooth things out
		FlxG.camera.follow(player, 1); 
		
		// Set up the enemies here
		_enemies = new FlxGroup();
		placeMonsters(Assets.getText("assets/data/monstacoords.csv"), Enemy);
		placeMonsters(Assets.getText("assets/data/lurkcoords.csv"), Lurker);
		
		_coins = new FlxGroup();
		placeCoins(Assets.getText("assets/data/coins.csv"), Coin);
		
		add(_coins);
		add(_enemies);
		
		Reg.score = 0;
		
		super.create();
		
		// Set up the individual bullets
		// Allow 4 bullets at a time
		for (i in 0...4)    
		{
			_bullets.add(new Bullet());
		}
		
		add(_badbullets);
		add(_bullets); 
		add(_gibs);
		add(_mongibs);
		
		// HUD - score
		_score = new FlxText(0, 0, FlxG.width);
		_score.setFormat(null, 16, FlxColor.YELLOW, "center", FlxText.BORDER_OUTLINE, 0x131c1b);
		_score.scrollFactor.set(0, 0);
		add(_score);
		
		// Set up the game over text
		_text1 = new FlxText(0, 30, FlxG.width, "Press R to Restart");
		_text1.setFormat(null, 40, FlxColor.RED, "center", FlxText.BORDER_NONE);
		_text1.visible = false;
		_text1.antialiasing = true;
		_text1.scrollFactor.set(0, 0);
		// Add last so it goes on top, you know the drill.
		add(_text1); 
		
		FlxG.sound.playMusic("assets/music/ScrollingSpace.mp3", 0.5);
	}
	
	override public function update():Void 
	{
		FlxG.collide(player, map);
		FlxG.collide(_enemies, map);
		FlxG.collide(_gibs, map);
		FlxG.collide(_bullets, map);
		FlxG.collide(_badbullets, map);
		
		super.update();
		
		_score.text = '$' + Std.string(Reg.score);
		
		if (!player.alive)
		{
			_text1.visible = true;
			
			if (FlxG.keys.justPressed.R) 
			{
				_restart = true;
			}
		}
		
		FlxG.overlap(player, _enemies, hitPlayer);
		FlxG.overlap(_bullets, _enemies, hitmonster);
		FlxG.overlap(player, _coins, collectCoin);
		FlxG.overlap(player, _badbullets, hitPlayer);
		
		if (_restart) 
		{
			FlxG.switchState(new PlayState());
		}
	}
	
	private function collectCoin(P:FlxObject, C:FlxObject):Void 
	{
		C.kill();
	}
	
	private function hitPlayer(P:FlxObject, Monster:FlxObject):Void 
	{
		if (Std.is(Monster, Bullet))
		{
			Monster.kill();
		}
		
		if (Monster.health > 0)
		{
			// This should still be more interesting
			P.hurt(1); 
		}
	}
	
	private function hitmonster(Blt:FlxObject, Monster:FlxObject):Void 
	{
		if (!Monster.alive) 
		{ 
			// Just in case
			return; 
		}  
		
		if (Monster.health > 0) 
		{
			Blt.kill();
			Monster.hurt(1);
		}
	}
	
	private function placeMonsters(MonsterData:String, Monster:Class<FlxObject>):Void
	{
		var coords:Array<String>;
		// Each line becomes an entry in the array of strings
		var entities:Array<String> = MonsterData.split("\n");   
		
		for (j in 0...(entities.length)) 
		{
			// Split each line into two coordinates
			coords = entities[j].split(","); 
			
			if (Monster == Enemy)
			{
				_enemies.add(new Enemy(Std.parseInt(coords[0]), Std.parseInt(coords[1]), player, _mongibs)); 
			}
			else if (Monster == Lurker)
			{ 
				_enemies.add(new Lurker(Std.parseInt(coords[0]), Std.parseInt(coords[1]), player, _badbullets));
			}
		}
	}
	
	private function placeCoins(CoinData:String, Sparkle:Class<FlxObject>):Void 
	{
		var coords:Array<String>;
		// Each line becomes an entry in the array of strings
		var entities:Array<String> = CoinData.split("\n");   
		
		for (j in 0...(entities.length)) 
		{
			//Split each line into two coordinates
			coords = entities[j].split(",");  
			
			if (Sparkle == Coin)
			{
				_coins.add(new Coin(Std.parseInt(coords[0]), Std.parseInt(coords[1]))); 
			}
		}
	}
}