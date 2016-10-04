//
//  GameScene.swift
//  Flappy Felipe
//
//  Created by Oscar Villavicencio on 9/29/16.
//  Copyright © 2016 Unicorn. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

enum Layer: CGFloat{
    case background
    case obstacle
    case foreground
    case player
    case ui
    case flash
}

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Player: UInt32 = 0x1 << 0
    static let Obstacle: UInt32 = 0x1 << 1
    static let Ground: UInt32 = 0x1 << 2
}

enum GameState {
    case mainMenu
    case play
    case falling
    case showingScore
    case gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    //movement constants
    let kGravity: CGFloat = -350.0
    let kFlap: CGFloat = 150.0
    let kBackgroundMotion: CGFloat = 250.0
    let kNumForegrounds = 2
    let kBottomObstacleMinFraction: CGFloat = 0.1 // percent of playableHeight
    let kBottomObstacleMaxFraction: CGFloat = 0.6 // percent of playableHeight
    let kObstacleGapToPlayerHeightRatio: CGFloat = 3.5 // ratio of gap between obstacles to player height
    let kFirstSpawnDelay: TimeInterval = 0.5
    let kEverySpawnDelay: TimeInterval = 2
    let kAnimationDelay: TimeInterval = 0.3
    //atlas
    let birdAtlas = SKTextureAtlas(named: "sprites.atlas")
    var birdSprites = Array<SKTexture>()
    //game sprites and mechanics
    let worldNode = SKNode()
    var scoreLabel = SKLabelNode()
    let kFontName = "AmericanTypewriter-Bold"
    let kFontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
    let kMargin: CGFloat = 20.0
    var playableHeight: CGFloat = 0
    var playableStart: CGFloat = 0
    var player = SKSpriteNode(imageNamed: "Bird0")
    let background = SKSpriteNode(imageNamed: "Background")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var playerVelocity = CGPoint.zero
    var backgroundVelocity = CGPoint.zero
    var pipeHeight: CGFloat = 150
    var pipeHeightTop: CGFloat = 150
    var hitGround = false
    var hitObstacle = false
    var gameState: GameState = .mainMenu
    var score = 0
    
    
    
    //sounds
    let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        addChild(worldNode)
        worldNode.name = "world"
        setupBackground()
        setupForeground()
        setupPlayer()
    }
    
    func setupBackground() {
        worldNode.addChild(background)
        background.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        background.position = CGPoint(x: size.width/2, y: size.height)
        background.zPosition = Layer.background.rawValue
        
        playableHeight = background.size.height
        playableStart = size.height - playableHeight
        // physics engine support - add to scene itself since it's a world boundary
        let lowerLeft = CGPoint(x: 0, y: playableStart)
        let lowerRight = CGPoint(x: size.width, y: playableStart)
        self.physicsBody = SKPhysicsBody(edgeFrom: lowerLeft, to: lowerRight)
        self.physicsBody!.categoryBitMask = PhysicsCategory.Ground
        self.physicsBody!.contactTestBitMask = PhysicsCategory.Player
        self.physicsBody!.collisionBitMask = PhysicsCategory.None
        self.physicsBody!.isDynamic = false
        
    }
    
    func setupForeground(){
        for i in 0..<kNumForegrounds{
            let foreground = SKSpriteNode(imageNamed: "Ground")
            foreground.anchorPoint = CGPoint(x:0, y:1)
            foreground.position = CGPoint(x:CGFloat(i) * foreground.size.width, y:playableStart)
            foreground.zPosition = Layer.foreground.rawValue
            foreground.name = "foreground"
            worldNode.addChild(foreground)
        }
        
    }
    
    func setupPlayer(){
        animateBird()
        player.position = CGPoint(x: size.width * 0.2, y: playableHeight * 0.4 + playableStart)
        player.zPosition = Layer.player.rawValue
        
        let offsetX = player.size.width * player.anchorPoint.x
        let offsetY = player.size.height * player.anchorPoint.y
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 22 - offsetX, y: 0 - offsetY))
        path.addLine(to: CGPoint(x: 34 - offsetX, y: 3 - offsetY))
        path.addLine(to: CGPoint(x: 39 - offsetX, y: 18 - offsetY))
        path.addLine(to: CGPoint(x: 39 - offsetX, y: 24 - offsetY))
        path.addLine(to: CGPoint(x: 25 - offsetX, y: 29 - offsetY))
        path.addLine(to: CGPoint(x: 20 - offsetX, y: 29 - offsetY))
        path.addLine(to: CGPoint(x: 5 - offsetX, y: 16 - offsetY))
        path.addLine(to: CGPoint(x: 4 - offsetX, y: 7 - offsetY))
        path.addLine(to: CGPoint(x: 4 - offsetX, y: 1 - offsetY))
        path.addLine(to: CGPoint(x: 4 - offsetX, y: 0 - offsetY))
        
        path.closeSubpath()
        
        player.physicsBody = SKPhysicsBody(polygonFrom: path)
        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        player.physicsBody!.contactTestBitMask = PhysicsCategory.Obstacle | PhysicsCategory.Ground
        player.physicsBody!.collisionBitMask = PhysicsCategory.None
        player.physicsBody!.isDynamic = true
        
        worldNode.addChild(player)
        
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.4)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        let `repeat` = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
        player.run(`repeat`, withKey: "Wobble")
        
    }
    
    func setupLabel() {
        scoreLabel = SKLabelNode(fontNamed: kFontName)
        // Ray says that the magic color numbers came from him
        scoreLabel.fontColor = kFontColor
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - kMargin)
        scoreLabel.text = "\(score)"
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = Layer.ui.rawValue
        worldNode.addChild(scoreLabel)
    }
    
    func animateBird(){
        birdSprites.append(birdAtlas.textureNamed("Bird0"))
        birdSprites.append(birdAtlas.textureNamed("Bird1"))
        birdSprites.append(birdAtlas.textureNamed("Bird2"))
        birdSprites.append(birdAtlas.textureNamed("Bird3"))
        
        player = SKSpriteNode(texture:birdSprites[0])
        
        let animateBird = SKAction.animate(with: self.birdSprites, timePerFrame: 0.1, resize: false, restore: true)
        let repeatAction = SKAction.repeatForever(animateBird)
        self.player.run(repeatAction)
    }
    
    func flapPlayer(){
        playerVelocity = CGPoint(x: 0, y: kFlap)
        //self.run(flapAction)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch?.location(in: self)
        switch gameState {
            case .mainMenu:
                if (touchLocation?.y)! < size.height{
                    switchToPlay()
                    setupLabel()
                    // Start spawning
                    startSpawn()
                }
            break
            
            case .play:
                flapPlayer()
            break
            
            case .falling:
            break
            
            case .showingScore:
                gameState = .showingScore
            break
            
            case .gameOver:
                if (touchLocation?.x)! > size.width * 0.6 {
                    //share
                } else {
                    switchToNewGame()
                }
            break
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else{
            dt = 0
        }
        
        lastUpdateTime = currentTime
        
        switch gameState{
            case .mainMenu:
                break
            case .play:
                updatePlayer()
                updateForeground()
                checkHitGround()
                checkHitObstacle()
                updateScore()
                break
            case .falling:
                updatePlayer()
                checkHitGround()
                break
            case .showingScore:
                break
            case .gameOver:
                break
        }
        
        
    }
    
    func switchToNewGame() {
        if let skView = view {
            gameState = .mainMenu
            let newScene = GameScene(size: size)
            let transition = SKTransition.fade(with: SKColor.black, duration: 0.5) //crossFadeWithDuration(1.0)
            run(popAction)
            skView.presentScene(newScene, transition: transition)
        }
    }
    
    func updatePlayer(){
        //Apply Gravity
        let gravity = CGPoint(x: 0, y: kGravity)
        
        let gravityStep = gravity * CGFloat(dt)
        
        playerVelocity += gravityStep
        
        //Apply Velocity
        let velocityStep = playerVelocity * CGFloat(dt)
        player.position += velocityStep
        player.position.y = min(player.position.y, size.height)
        
        /*
        if player.position.y - player.size.height/2 < playableStart{
            player.position = CGPoint(x: player.position.x, y: playableStart + player.size.height/2)
        }*/
        
    }
    
    func createObstacle() -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: "Cactus")
        sprite.userData = NSMutableDictionary()
        
        // physics body for obstacle [**[see FN.3]**]
        let offsetX = sprite.size.width * sprite.anchorPoint.x
        let offsetY = sprite.size.height * sprite.anchorPoint.y
        
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: 4 - offsetX, y: 314 - offsetY))
        path.addLine(to: CGPoint(x: 51 - offsetX, y: 314 - offsetY))
        path.addLine(to: CGPoint(x: 49 - offsetX, y: 1 - offsetY))
        path.addLine(to: CGPoint(x: 2 - offsetX, y: 0 - offsetY))
        
        path.closeSubpath()
        
        sprite.physicsBody = SKPhysicsBody(polygonFrom: path)
        sprite.physicsBody!.categoryBitMask = PhysicsCategory.Obstacle
        sprite.physicsBody!.contactTestBitMask = PhysicsCategory.Player
        sprite.physicsBody!.collisionBitMask = PhysicsCategory.None
        sprite.physicsBody!.isDynamic = false
        sprite.zPosition = Layer.obstacle.rawValue
        
        return sprite
    }
    
    func spawnObstacle() {
        let bottomObstacle = createObstacle()
        let startX = size.width + bottomObstacle.size.width/2 // fully off screen to the right
        
        let bottomObstacleMidpointY = (playableStart - bottomObstacle.size.height/2)
        let bottomObstacleMin = bottomObstacleMidpointY + playableHeight * kBottomObstacleMinFraction
        let bottomObstacleMax = bottomObstacleMidpointY + playableHeight * kBottomObstacleMaxFraction
        bottomObstacle.position = CGPoint(x: startX, y: randomBetweenNumbers(bottomObstacleMin, secondNum: bottomObstacleMax))
        
        bottomObstacle.name = "BottomObstacle"
        worldNode.addChild(bottomObstacle)
        
        let topObstacle = createObstacle()
        topObstacle.zRotation = CGFloat(180).degreesToRadians() // flip it 180deg around
        let bottomObstacleTopY = (bottomObstacle.position.y + bottomObstacle.size.height/2)
        let playerGap = kObstacleGapToPlayerHeightRatio * player.size.height
        topObstacle.position = CGPoint(x: startX, y: bottomObstacleTopY + playerGap + topObstacle.size.height/2)
        topObstacle.name = "TopObstacle"
        worldNode.addChild(topObstacle)
        
        // set up the obstacle's move
        let moveX = size.width + topObstacle.size.width // from offscreen right to offscreen left (includes one obj.width)
        let moveDuration = moveX / kBackgroundMotion // points divided by points/s = seconds
        // create a sequence of actions to do the move
        let sequence = SKAction.sequence([
            SKAction.moveBy(x: -moveX, y: 0, duration: TimeInterval(moveDuration)),
            SKAction.removeFromParent()
            ])
        // both obstacles run the same sequence and move together across the screen, right to left
        topObstacle.run(sequence)
        bottomObstacle.run(sequence)
    }
    
    func setupScorecard() {
        if score > bestScore() {
            setBestScore(bestScore: score)
        }
        
        let scorecard = SKSpriteNode(imageNamed: "ScoreCard")
        scorecard.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        scorecard.name = "Tutorial"
        scorecard.zPosition = Layer.ui.rawValue
        worldNode.addChild(scorecard)
        
        let lastScore = SKLabelNode(fontNamed: kFontName)
        lastScore.fontColor = kFontColor
        lastScore.position = CGPoint(x: -scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
        lastScore.text = "\(score)"
        lastScore.zPosition = Layer.ui.rawValue
        scorecard.addChild(lastScore)
        
        let bestScoreLabel = SKLabelNode(fontNamed: kFontName)
        bestScoreLabel.fontColor = kFontColor
        bestScoreLabel.position = CGPoint(x: scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
        bestScoreLabel.text = "\(self.bestScore())"
        bestScoreLabel.zPosition = Layer.ui.rawValue
        scorecard.addChild(bestScoreLabel)
        
        let yDistance = scorecard.size.height/2 + kMargin
        let gameOver = SKSpriteNode(imageNamed: "GameOver")
        gameOver.position = CGPoint(x: size.width/2, y: size.height/2 + yDistance + gameOver.size.height/2)
        gameOver.zPosition = Layer.ui.rawValue
        worldNode.addChild(gameOver)
        
        let okButton = SKSpriteNode(imageNamed: "Button")
        okButton.position = CGPoint(x: size.width * 0.25, y: size.height/2 - yDistance - okButton.size.height/2)
        okButton.zPosition = Layer.ui.rawValue
        worldNode.addChild(okButton)
        
        let ok = SKSpriteNode(imageNamed: "OK")
        ok.position = CGPoint.zero
        ok.zPosition = Layer.ui.rawValue
        okButton.addChild(ok)
        
        let shareButton = SKSpriteNode(imageNamed: "Button")
        shareButton.position = CGPoint(x: size.width * 0.75, y: size.height/2 - yDistance - shareButton.size.height/2)
        shareButton.zPosition = Layer.ui.rawValue
        worldNode.addChild(shareButton)
        
        let share = SKSpriteNode(imageNamed: "Share")
        share.position = CGPoint.zero
        share.zPosition = Layer.ui.rawValue
        shareButton.addChild(share)
        
        // animation: gameOver scales and fades in at its final position (no motion)
        gameOver.setScale(0)
        gameOver.alpha = 0
        let group = SKAction.group([
            SKAction.fadeIn(withDuration: kAnimationDelay),
            SKAction.scale(to: 1.0, duration: kAnimationDelay)
            ])
        group.timingMode = .easeInEaseOut
        gameOver.run(SKAction.sequence([
            SKAction.wait(forDuration: kAnimationDelay),
            group
            ]))
        
        // scorecard slides in from the bottom
        scorecard.position = CGPoint(x: size.width/2, y: -scorecard.size.height/2)
        let moveTo = SKAction.move(to: CGPoint(x: size.width/2, y: size.height/2), duration: kAnimationDelay)
        moveTo.timingMode = .easeInEaseOut
        scorecard.run(SKAction.sequence([
            SKAction.wait(forDuration: kAnimationDelay * 2),
            moveTo
            ]))
        
        // OK and Share buttons fade in, also in place
        okButton.alpha = 0
        shareButton.alpha = 0
        let fadeIn = SKAction.sequence([
            SKAction.wait(forDuration: kAnimationDelay * 3),
            SKAction.fadeIn(withDuration: kAnimationDelay)
            ])
        fadeIn.timingMode = .easeInEaseOut
        okButton.run(fadeIn)
        shareButton.run(fadeIn)
        
        // run a sound-track in parallel, ending in a game state change
        let pops = SKAction.sequence([
            SKAction.wait(forDuration: kAnimationDelay),
            popAction,
            SKAction.wait(forDuration: kAnimationDelay),
            popAction,
            SKAction.wait(forDuration: kAnimationDelay),
            popAction,
            SKAction.run(switchToGameOver)
            ])
        run(pops)
    }
    
    func switchToMainMenu(){
        gameState = .mainMenu
        
        setupBackground()
        setupForeground()
        setupPlayer()
    }
    
    func startSpawn(){
        let firstDelay = SKAction.wait(forDuration: kFirstSpawnDelay)
        let spawn = SKAction.run(spawnObstacle)
        let everyDelay = SKAction.wait(forDuration: kEverySpawnDelay)
        let spawnSequence = SKAction.sequence([
            spawn, everyDelay
            ])
        let foreverSpawn = SKAction.repeatForever(spawnSequence)
        let overallSequence = SKAction.sequence([
            firstDelay, foreverSpawn
            ])
        // scene itself should run this, since the code isn't specific to any nodes
        run(overallSequence, withKey: "spawn")
    }
    
    func stopSpawning() {
        removeAction(forKey: "spawn")
        // since Top and Bottom obstacles have different names (due to scoring), we need to do this removal for both
        ["TopObstacle", "BottomObstacle"].forEach() {
            self.worldNode.enumerateChildNodes(withName: $0, using: {node, stop in
                node.removeAllActions()
            })
        }
    }
    
    func updateForeground() {
        worldNode.enumerateChildNodes(withName: "foreground", using: { node, stop in
            if let foreground = node as? SKSpriteNode {
                let moveAmount = CGPoint(x: -self.kBackgroundMotion * CGFloat(self.dt), y: 0)
                foreground.position += moveAmount
                
                if foreground.position.x < -foreground.size.width {
                    foreground.position += CGPoint(x: foreground.size.width * CGFloat(self.kNumForegrounds), y: 0)
                }
            }
        })
        
    }
    
    func bestScore() -> Int {
        return UserDefaults.standard.integer(forKey: "BestScore")
    }
    
    func setBestScore(bestScore: Int) {
        UserDefaults.standard.set(bestScore, forKey: "BestScore")
        UserDefaults.standard.synchronize()
    }
    
    func updateScore() {
        let typicalObstacle = "TopObstacle" // pick one (top or bottom) arbitrarily, else we would double-score
        worldNode.enumerateChildNodes(withName: typicalObstacle, using: { node, stop in
            if let obstacle = node as? SKSpriteNode {
                // if current obstacle has a dictionary with the key "Passed", then we're done looking at that obstacle
                if let passed = obstacle.userData?["Passed"] as? NSNumber, passed.boolValue {
                    return
                }
                // else if player's position is beyond the obstacle's right edge...
                if self.player.position.x > obstacle.position.x + obstacle.size.width/2 {
                    // bump the score
                    self.addToScore()
                    self.scoreLabel.text = "\(self.score)"
                    // play a sound
                    self.run(self.coinAction)
                    // and set the Passed key in its dictionary
                    obstacle.userData?["Passed"] = true
                }
            }
        })
    }
    
    func randomBetweenNumbers(_ firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func switchToPlay() {
        gameState = .play
        
        
        // Stop wobbling
        player.removeAction(forKey: "Wobble")
        
        // Start spawning
        startSpawn()
        
        flapPlayer() // give the user a chance!
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //GAMEOVER = TRUE
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        
        if other.categoryBitMask == PhysicsCategory.Ground {
            hitGround = true
            print("hit ground?")
        }
        if other.categoryBitMask == PhysicsCategory.Obstacle {
            hitObstacle = true
            print("hit cactus?")
        }
    }
    
    func addToScore(){
        score += 1
        
    }
    
    func checkHitGround() {
        if hitGround {
            hitGround = false
            playerVelocity = CGPoint(x: 0, y: 0)
            player.zRotation = CGFloat(-90).degreesToRadians()
            player.position = CGPoint(x: player.position.x, y: playableStart + player.size.width/2)
            run(hitGroundAction)
            switchToShowScore()
        }
    }
    func checkHitObstacle() {
        if hitObstacle {
            hitObstacle = false
            switchToFalling()
        }
    }
    
    func switchToFalling() {
        gameState = .falling
        
        // Screen shake
        let shake = SKAction.screenShakeWithNode(worldNode, amount: CGPoint(x: 0.0, y: 7.0), oscillations: 10, duration: 1.0)
        worldNode.run(shake)
        
        // Screen flash
        let whiteNode = SKSpriteNode(color: SKColor.white, size: size)
        whiteNode.position = CGPoint(x: size.width/2, y: size.height/2)
        whiteNode.zPosition = Layer.flash.rawValue
        worldNode.addChild(whiteNode)
        
        whiteNode.run(SKAction.removeFromParentAfterDelay(0.01))
        
        //sequence the sound effects (whack, then falling)
        run(SKAction.sequence([whackAction,
                                     SKAction.wait(forDuration: 0.1),
                                    fallingAction]))
        player.removeAllActions()
        stopSpawning()
    }
    
    func switchToGameOver(){
        gameState = .gameOver
    }
    
    func switchToShowScore(){
        gameState = .showingScore
        
        player.removeAllActions()
        stopSpawning()
        setupScorecard()
    }
    
}
    

