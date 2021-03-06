package
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import org.flixel.*;
	
	public class ScreenState extends FlxState
	{
		[Embed(source="../assets/images/Pointer.png")] protected static var imgPointer:Class;
		
		private var _fx:FlxSprite;
		private var blur:BlurFilter;
		private var _rect:Rectangle;
		private var _point:Point;
		private var lastTimeStamp:int = 0;
		private var currentTimeStamp:int = 0;
		
		private var fpsBuffer:Array;
		private var fpsIndex:uint;
		
		public static var grid:Grid;
		public static var blackholes:FlxGroup;
		private static var particles:FlxGroup;
		private static var entities:FlxGroup;
		private static var cursor:FlxSprite;
		private static var displayText:FlxText;
		private static var inverseSpawnChance:Number = 60;
		private static var _spawnPosition:FlxPoint;
		
		public function ScreenState()
		{
			super();
		}
		
		override public function create():void
		{
			FlxG.setDebuggerLayout(FlxG.DEBUGGER_MICRO);
			super.create();
			GameInput.create();
			GameSound.create();
			
			fpsBuffer = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
			fpsIndex = 0;
			
			// Neither the grid nor the particles group are added to the FlxState here. Instead, their update() and draw() routines will
			// be called in a custom order.
			var _gridRect:Rectangle = new Rectangle(0, 0, FlxG.width, FlxG.height);
			grid = new Grid(_gridRect, FlxG.width / 20, FlxG.height / 20, 8);
			
			particles = new FlxGroup();
			for (i = 0; i < 2500; i++) particles.add(new Particle());
						
			entities = new FlxGroup();
			entities.add(new PlayerShip());
			for (var i:uint = 0; i < 100; i++) entities.add(new Bullet());
			for (i = 0; i < 200; i++) entities.add(new Enemy());
			add(entities);
			
			blackholes = new FlxGroup();
			for (i = 0; i < 2; i++) blackholes.add(new Enemy());
			add(blackholes);
			
			cursor = new FlxSprite(FlxG.mouse.x, FlxG.mouse.x);
			cursor.loadGraphic(imgPointer);
			add(cursor);
			
			displayText = new FlxText(0, 0, FlxG.width, "");
			displayText.setFormat(null, 16, 0xffffff, "right");
			add(displayText);
			
			//These are used to implement the glow effect.
			_fx = new FlxSprite();
			_fx.makeGraphic(FlxG.width, FlxG.height, 0, true);
			_fx.antialiasing = true;
			_fx.blend = "screen";
			_rect = new Rectangle(0, 0, FlxG.width, FlxG.height);
			_point = new Point();
			blur = new BlurFilter(8, 8, BitmapFilterQuality.LOW);
		}
		
		override public function update():void
		{	
			GameInput.update();
			super.update();
			grid.update();
			particles.update();
			
			cursor.x = FlxG.mouse.x;
			cursor.y = FlxG.mouse.y;
			
			if (FlxG.random() < 1 / inverseSpawnChance) makeEnemy(Enemy.SEEKER);
			if (FlxG.random() < 1 / inverseSpawnChance) makeEnemy(Enemy.WANDERER);
			if (blackholes.countLiving() < 2) if (FlxG.random() < 1 / (inverseSpawnChance * 10)) makeBlackhole();
			if (inverseSpawnChance > 20) inverseSpawnChance -= 0.005;
			
			FlxG.overlap(entities, entities, handleCollision);
			FlxG.overlap(blackholes, entities, handleCollision);
			
			// Calculate average framerate over the past 10 frames.
			if (fpsIndex + 1 >= fpsBuffer.length) fpsIndex = 0;
			else fpsIndex++;
			fpsBuffer[fpsIndex] = getTimer() - lastTimeStamp;
			var _timeTotalInMilliseconds:int = 0;
			for (var i:int = 0; i < fpsBuffer.length; i++)
				_timeTotalInMilliseconds += fpsBuffer[i];
			lastTimeStamp = getTimer();
			
			if (PlayerShip.isGameOver) 
			{
				displayText.alignment = "center";
				displayText.offset.y = 16 - 0.5 * FlxG.height;
				displayText.text = "Game Over\n" + "Your Score: " + PlayerShip.score + "\n" + "High Score: " + PlayerShip.highScore;
			}
			else 
			{
				displayText.alignment = "right";
				displayText.offset.y = 0;
				displayText.text = "Lives: " + PlayerShip.lives + "\t\tScore: " + PlayerShip.score + "\t\tMultiplier: " 
					+ PlayerShip.multiplier;
				displayText.text += "\n" + int((500 * fpsBuffer.length) / _timeTotalInMilliseconds) + " fps";
			}
			

		}
		
		override public function draw():void
		{
			grid.draw();
			particles.draw();
			FlxG.camera.screen.pixels.draw(FlxG.flashGfxSprite);
			
			super.draw();
			
			//Apply glow effect, may cause significant framerate decrease
			_fx.stamp(FlxG.camera.screen);
			FlxG.camera.screen.pixels.applyFilter(FlxG.camera.screen.pixels, _rect, _point, blur);
			_fx.draw();
		}
		
		public function handleCollision(Object1:FlxObject, Object2:FlxObject):void
		{
			var DistanceSquared:Number = 0;
			var Collided:Boolean = false;
			if (Object1 is Entity && Object2 is Entity)
			{
				var DX:Number = (Object1 as Entity).position.x - (Object2 as Entity).position.x;
				var DY:Number = (Object1 as Entity).position.y - (Object2 as Entity).position.y;
				var CombinedRadius:Number = (Object1 as Entity).radius + (Object2 as Entity).radius;
				
				DistanceSquared = DX * DX + DY * DY; //FlxU.getDistance((Object1 as Entity).position, (Object2 as Entity).position);
				if (DistanceSquared <= CombinedRadius * CombinedRadius) Collided = true;
				else Collided = false;
			}
			if (!Collided) return;
			(Object1 as Entity).collidesWith(Object2 as Entity, DistanceSquared);
			(Object2 as Entity).collidesWith(Object1 as Entity, DistanceSquared);
		}
		
		/*public function circularCollision(Object1:FlxObject, Object2:FlxObject):Boolean
		{
			var _distanceFromCenters:Number
			if (Object1 is Entity && Object2 is Entity)
			{
				_distanceFromCenters = FlxU.getDistance((Object1 as Entity).position, (Object2 as Entity).position);
				if (_distanceFromCenters < (Object1 as Entity).radius + (Object2 as Entity).radius) return true;
				else return false;
			}
			else return false;
		}*/
		
		public static function reset():void
		{
			inverseSpawnChance = 60;
		}
		
		public static function makeBullet(PositionX:Number, PositionY:Number, Angle:Number, Speed:Number):Boolean
		{
			var _bullet:Bullet = Bullet(entities.getFirstAvailable(Bullet));
			if (_bullet) 
			{
				(_bullet as Bullet).reset(PositionX, PositionY);
				_bullet.angle = Angle;
				_bullet.velocity.x = Speed * Math.cos((Angle / 180) * Math.PI);
				_bullet.velocity.y = Speed * Math.sin((Angle / 180) * Math.PI);
				return true;
			}
			else return false;
		}
		
		public static function makeEnemy(Type:uint):Boolean
		{
			var _enemy:Enemy = Enemy(entities.getFirstAvailable(Enemy));
			if (_enemy) 
			{
				var MinimumDistanceFromPlayer:Number = 150;
				_enemy.type = Type;
				_enemy.position = getSpawnPosition(_enemy.position, MinimumDistanceFromPlayer);
				_enemy.reset(_enemy.position.x, _enemy.position.y);
				return true;
			}
			else return false;
		}
		
		public static function makeBlackhole():Boolean
		{
			var _enemy:Enemy = Enemy(blackholes.getFirstAvailable(Enemy));
			if (_enemy) 
			{
				var MinimumDistanceFromPlayer:Number = 20
				_enemy.type = Enemy.BLACK_HOLE;
				_enemy.position = getSpawnPosition(_enemy.position, MinimumDistanceFromPlayer);
				_enemy.reset(_enemy.position.x, _enemy.position.y);
				return true;
			}
			else return false;
		}
		
		public static function makeParticle(Type:uint, PositionX:Number, PositionY:Number, Angle:Number, Speed:Number, Color:uint = FlxG.WHITE, Glowing:Boolean = false):Boolean
		{
			Particle.index += 1;
			if (Particle.index >= Particle.max) Particle.index = 0;
			var _overwritten:Boolean = false;
			var _particle:Particle = particles.members[Particle.index];
			if (_particle.exists) _overwritten = true;

			_particle.reset(PositionX, PositionY);
			_particle.type = Type;
			_particle.lineColor = Color;
			_particle.setVelocity((Angle * Math.PI) / 180, Speed);
			_particle.maxSpeed = Speed;
			_particle.isGlowing = Glowing;
			return _overwritten;
		}
		
		public static function makeExplosion(Type:uint, PositionX:Number, PositionY:Number, NumberOfParticles:uint, Speed:Number, Color:uint = 0xff00ff, BlendColor:int = -1):void
		{
			var _mixColors:Boolean = true;
			var _mixedColor:uint;
			if (BlendColor < 0) 
			{
				BlendColor = _mixedColor = Color;
				_mixColors = false;
			}
			for (var i:uint = 0; i < NumberOfParticles; i++)
			{
				if (_mixColors) _mixedColor = Entity.interpolateRGB(Color, BlendColor, FlxG.random());
				makeParticle(Type, PositionX, PositionY, 360 * FlxG.random(), Speed * (1 - 0.5 * FlxG.random()), _mixedColor);
			}
		}
		
		public static function getSpawnPosition(Source:FlxPoint, MinimumDistanceFromPlayer:Number):FlxPoint
		{
			var _x:int;
			var _y:int;
			var _xDelta:Number;
			var _yDelta:Number;
			
			do
			{
				_x = int(FlxG.random() * FlxG.width);
				_y = int(FlxG.random() * FlxG.height);
				_xDelta = PlayerShip.instance.position.x - _x;
				_yDelta = PlayerShip.instance.position.y - _y;
			} while (_xDelta * _xDelta + _yDelta * _yDelta < MinimumDistanceFromPlayer * MinimumDistanceFromPlayer);
			
			Source.x = _x;
			Source.y = _y;
			
			return Source;
		}

	}
}