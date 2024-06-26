import wollok.game.*
import world.*
import graphics.*

/*
 * ME OLVIDE DE DECIR
 * Antes de crear nuevas balas, acuerdense de usar el sistema de pooling que hice por razones de rendimiento
 * Asi que cada vez que necesiten crear una nueva bala, en vez de instanciar una bala usen el metodo shootBullet de bulletManager
 * y en vez de remover el visual de la bala usen el metodo removeBullet de bulletManager
 */

// Clase base para los pickups de arma y curación
class Pickup {
    const property entityType = "pickup"
    var property position = game.at(0,0)
    var property tomado = false;
    
    method activar() {
        if (not game.hasVisual(self))
            game.addVisual(self)
    }
    method desactivar() {
        if (game.hasVisual(self)) 
            game.removeVisual(self)
    }
    method collide(p) {
        tomado = true;
        game.removeVisual(self)
        world.removeObjetoHabitacionActual(self)
    }
}

// Clase base para las armas
class Armas inherits Pickup{
    method municion() = null
    
    method danio() = null
    
    method agregarMunicion(cant) {}
    
    method usar(posicion, dir) {}
    
    method recargar() = null
    
    override method collide(p) {
        super(p)
        p.dropArmaEquipada()
        p.armaEquipada(self)
    }
}

// Clase para curación
class Curacion inherits Pickup{    
    override method collide(player) {
        super(player)
    }
}

// Clase para la Escopeta
class Escopeta inherits Armas {
    var property playerSprite = "sprites/player/player_1.png"
    
    const property municionBase = 5
    var municionDisponible = 0
    var municionUtilizable = 5
    const danio = 20
    
    override method municion() = municionDisponible
    
    override method danio() = danio
    
    override method agregarMunicion(cant) {
        municionDisponible += cant
    }
    
    override method usar(posicion, dir) {
        bulletManager.shootBullet(posicion, dir, BalaEscopeta)
        municionUtilizable -= 1
    }
    
    override method recargar() {
        if (municionDisponible - municionUtilizable < 0) {
            municionUtilizable += municionDisponible
            municionDisponible = 0
            return municionUtilizable
        }
        else {
            municionDisponible -= (municionBase - municionUtilizable)
            municionUtilizable += (municionBase - municionUtilizable)
            return municionUtilizable    
        }
    }
    
    method image() = "sprites/weapons/ShootGun_0.png"
}

// Clase para la Espada
class Espada inherits Armas {
    var property playerSprite = "sprites/player/player_5.png"
    
    const property municionBase = 0
    var municionUtilizable = 50
    var municionDisponible = 0
    var danio = 15
    
    override method municion() = null
    
    override method danio() = danio
    
    override method agregarMunicion(cant) {
        danio += cant
    }

    override method usar(posicion, dir) {
        bulletManager.shootBullet(posicion, dir, BalaEspada)
    }
    
    override method recargar() {
        if (municionDisponible - municionUtilizable < 0) {
            municionUtilizable += municionDisponible
            municionDisponible = 0
            return municionUtilizable
        }
        else {
            municionDisponible -= (municionBase - municionUtilizable)
            municionUtilizable += (municionBase - municionUtilizable)
            return municionUtilizable    
        }
    }
    
    method image() = "sprites/weapons/sword_normal.png"
}

// Clase para el Fusil
class Fusil inherits Armas {
    var property playerSprite = "sprites/player/player_6.png"
    
    const property municionBase = 14
    var municionDisponible = 0
    var municionUtilizable = 14
    const danio = 10
    
    override method municion() = municionDisponible
    
    override method danio() = danio
    
    override method agregarMunicion(cant) {
        municionDisponible += cant
    }
    
    override method usar(posicion, dir) {
        bulletManager.shootBullet(posicion, dir, BalaFusil)
        municionUtilizable -= 1
    }
    
    override method recargar() {
        if (municionDisponible - municionUtilizable < 0) {
            municionUtilizable += municionDisponible
            municionDisponible = 0
            return municionUtilizable
        }
        else {
            municionDisponible -= (municionBase - municionUtilizable)
            municionUtilizable += (municionBase - municionUtilizable)
            return municionUtilizable    
        }
    }
    
    method image() = "sprites/weapons/fusil.png"
}

// Objeto para manejar las balas
object bulletManager {
    var cantidadBalas = 12
    var property balas = []
    var puntero = 0 // Posición del array con la bala a disparar, se elegiría la bala con FIFO
    
    method initialize() {
        var cBalas = new Range(start = 1, end = cantidadBalas)
        cBalas.forEach({c => 
            var bala = new Bala()
            bala.position(game.at(-1, -1))
            game.addVisual(bala)
            balas.add(bala)
        })
    }
    
    method shootBullet(pos, dir, tipo) {
        balas.get(puntero).position(pos)
        balas.get(puntero).direction(dir)
        balas.get(puntero).danio(tipo.danio())
        balas.get(puntero).velocidad(tipo.velocidad())
        balas.get(puntero).tipo(tipo)
        balas.get(puntero).pasos(0)
        self.proxBala()
    }
    
    method removeBullet(b) {
        b.position(game.at(-1, -1))
    }
    
    method proxBala() {
        puntero = (puntero + 1) % cantidadBalas 
    }
    
    method resetBullets() {
        balas.forEach({b => b.position(game.at(-1, -1))})
    }
    
    method addBullet(bala) {
        balas.add(bala)
        game.addVisual(bala)
    }
}

// Clase para las balas
class Bala {
    var property danio = 10000     
    var property tipo = BalaNula // Leer BalaNula antes de tocar aca
    
    var property position = game.at(0,0)
    var property direction = 0
    var property pasos = 0 
    var velocidad = 200
    
    method initialize() {
        game.onTick(200, self.identity().toString()+"_moverTiro", { => self.moverBala() }) // Hace un evento para mover por instancia
    }
    
    method velocidad(vel) {
        game.removeTickEvent(self.identity().toString()+"_moverTiro")
        game.onTick(vel, self.identity().toString()+"_moverTiro", { => self.moverBala() }) // Hace un evento para mover por instancia
    }
    
    method image() = tipo.image()
    
    method moverBala() {
        if (self.outsideScreen()) {return 0}
        
        // Mueve la bala y verifica los pasos
        if (pasos < tipo.maxPasos()) {  // Reducimos el número de pasos para las balas de la espada
            self.moverBalaSegunDireccion()
            pasos += 1  // Incrementa el contador de pasos
        } 
        else {
            bulletManager.removeBullet(self) // Elimina la bala si ha superado el límite de pasos
        }

        return 0
    }
    
    method moverBalaSegunDireccion() {
        // Mueve la bala según la dirección
        if (direction == 0) position = position.up(1)
        if (direction == 1) position = position.right(1)
        if (direction == 2) position = position.down(1)
        if (direction == 3) position = position.left(1)
    }

    method outsideScreen() {
        return position.x() < 0 or position.y() < 0 or position.x() >= game.width() or position.y() >= game.height()
    }
    
    method collide(p) {} // NO TOCAR :) O LOS MATO (si el jugador toca una bala no pasa nada)
}

// Objeto para balas nulas
object BalaNula {
    const property maxPasos = 0
    const property danio = 0
    const property velocidad = 0
    
    var sprite = new AnimatedSprite(frame_duration = 100, images=[
        "sprites/weapons/swordbullet_0.png",
        "sprites/weapons/swordbullet_2.png",
        "sprites/weapons/swordbullet_1.png",
        "sprites/weapons/swordbullet_3.png"
    ])
    
    method image() = "a.png"
}

// Objeto para balas de fusil
object BalaFusil {
    const property maxPasos = 14
    const property danio = 10
    const property velocidad = 50
    
    var sprite = new AnimatedSprite(frame_duration = 100, images=[
        "sprites/weapons/bala_0.png",
        "sprites/weapons/bala_1.png",
        "sprites/weapons/bala_2.png",
        "sprites/weapons/bala_3.png"
    ])
    
    method initialize() {
        sprite.play()
    }
    method image() = sprite.image()
}

// Objeto para balas de escopeta
object BalaEscopeta {
    const property maxPasos = 6
    const property danio = 20
    const property velocidad = 90
    
    var sprite = new AnimatedSprite(frame_duration = 100, images=[
        "sprites/weapons/bala_0.png",
        "sprites/weapons/bala_1.png",
        "sprites/weapons/bala_2.png",
        "sprites/weapons/bala_3.png"
    ])
    var spriteManager = new AnimatedSpriteManager(sprite = sprite)
    
    method initialize() {
        sprite.play()
    }
    method image() = sprite.image()
}

// Objeto para balas de espada
object BalaEspada {
    const property maxPasos = 2
    const property danio = 15
    const property velocidad = 150
    
    var sprite = new AnimatedSprite(frame_duration = 100, images=[
        "sprites/weapons/swordbullet_0.png",
        "sprites/weapons/swordbullet_2.png",
        "sprites/weapons/swordbullet_1.png",
        "sprites/weapons/swordbullet_3.png"
    ])
    
    method initialize() {
        sprite.play()
    }
    method image() = sprite.image()
    
    method collide(enemigo) {
        enemigo.defensa(danio)
        game.removeVisual(self)
        world.removeObjetoHabitacionActual(self)
    }
}

// Clases para diferentes tipos de botiquines
class BotiquinP inherits Curacion {
    const salud = 25
    var numero = 0

    method image() = "sprites/healing/botiquin" +numero+ ".png"
    
    override method collide(player){
        super(player)
        var curacion = player.vida() + salud
        player.vida(curacion)
    }
}

class BotiquinM inherits Curacion {
    const salud = 50
    const numero = 1
        
    method image() = "sprites/healing/botiquin" +numero+ ".png"
        
    override method collide(player){
        super(player)
        var curacion = player.vida() + salud
        player.vida(curacion)
    }
}

class BotiquinG inherits Curacion {
    const salud = 75
    const numero = 2
    
    method image() = "sprites/healing/botiquin" +numero+ ".png"
    
    override method collide(player){
        super(player)
        var curacion = player.vida() + salud
        player.vida(curacion)
    }
}

// Clase para el Escudo
class Escudo inherits Curacion {
    var property escudo = 0
}
