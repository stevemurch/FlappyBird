//
//  GameScene.swift
//  FlappyBird
//
//  Created by Steve Murch on 1/13/18.
//  Copyright © 2018 Steve Murch. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird = SKSpriteNode()
    var bg = SKSpriteNode()
    var birdTexture = SKTexture()
    
    var scoreLabel = SKLabelNode()
    var currentScore = 0
    
    var gameOverLabel = SKLabelNode()
    var impulseAmount = 50
    
    var burstNode = SKEmitterNode()
    
    var timer = Timer()
    
    var endOfGameTimer = Timer()
    
    
    var explosionSound = SKAction.playSoundFileNamed("Explosion+1.mp3", waitForCompletion: false)
    var achievementSound = SKAction.playSoundFileNamed("achievement1.wav", waitForCompletion: false)
    
    var gameOver = false
    var readyForNewGame = false
    
    
    enum ColliderType: UInt32 {
        case Bird = 1
        case Object = 2 // pipe or the ground
        // would use 4, 8, etc. for binary value -- allowing multiple collision detection
        case Gap = 4
    }

    
    @objc func makePipes() {
        // pipes
        
        let gapHeight = bird.size.height * 4
        
        let gapMovementAmount = arc4random() % UInt32(self.frame.height / 2)    // random amount between 0 and half of screen height
        
        let pipeOffset = CGFloat(gapMovementAmount) - (self.frame.height / 4)
        
        let pipeTexture = SKTexture(imageNamed:"pipe1.png")
        let pipe1 = SKSpriteNode(texture:pipeTexture)
        pipe1.position = CGPoint(x: self.frame.width, y: self.frame.midY + (pipeTexture.size().height / 2) + gapHeight / 2 + pipeOffset)
        
        pipe1.physicsBody = SKPhysicsBody(rectangleOf: pipeTexture.size())
        pipe1.physicsBody!.isDynamic = false
        
        pipe1.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        
        
        let pipe2Texture = SKTexture(imageNamed:"pipe2.png")
        let pipe2 = SKSpriteNode(texture:pipe2Texture)
        pipe2.position = CGPoint(x: self.frame.width, y: self.frame.midY - (pipe2Texture.size().height / 2) - gapHeight / 2 + pipeOffset)
        
        pipe2.physicsBody = SKPhysicsBody(rectangleOf: pipe2Texture.size())
        pipe2.physicsBody!.isDynamic = false
        
        pipe2.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        
        
        let movePipes = SKAction.move(by:CGVector(dx:-2*self.frame.width , dy:0), duration: TimeInterval(self.frame.width / 100))
        let removePipes = SKAction.removeFromParent()
        
        let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])
        
        pipe1.run(moveAndRemovePipes)
        pipe2.run(moveAndRemovePipes)
        
        self.addChild(pipe1)
        self.addChild(pipe2)
        
        // invisible gap measures score
        let gap = SKNode()
        gap.position = CGPoint(x:self.frame.midX + self.frame.width+pipe1.texture!.size().width + bird.texture!.size().width, y:CGFloat(self.frame.midY + pipeOffset))
        gap.physicsBody = SKPhysicsBody(rectangleOf:CGSize(width:pipeTexture.size().width, height:gapHeight))
        gap.physicsBody!.isDynamic = false
        
        gap.physicsBody!.contactTestBitMask = ColliderType.Bird.rawValue // want to test when Bird hits this to increment score
        gap.physicsBody!.categoryBitMask = ColliderType.Gap.rawValue
        gap.physicsBody!.collisionBitMask = ColliderType.Gap.rawValue
        
        gap.run(moveAndRemovePipes)
        self.addChild(gap)
        
    }
    
    
    
    override func didMove(to view: SKView) {
        // get notified of pauses
        NotificationCenter.default.addObserver(self, selector: #selector(pauseLevel), name: .UIApplicationWillResignActive, object: nil)
        
        self.physicsWorld.contactDelegate = self
        
        setupGame()
        
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func pauseLevel(){
        currentScore = currentScore + 100
        print("PAUSING GAME pauseLevel")
        scoreLabel.text = String(currentScore)
    }
    
    
    func setupGame()
    {
        
        // timer for pipes
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.makePipes), userInfo: nil, repeats: true)
        readyForNewGame = false
        
        let bgTexture = SKTexture(imageNamed:"bg.png")
        
        let moveBGAnimation = SKAction.move(by:CGVector(dx:-bgTexture.size().width, dy:0), duration:5)
        let shiftBGAnimation = SKAction.move(by:CGVector(dx:bgTexture.size().width, dy:0), duration:0)
        let moveBGForever = SKAction.repeatForever(SKAction.sequence([moveBGAnimation, shiftBGAnimation]))
        
        var i:CGFloat = 0
        while i < 3 {
            
            // background scroll -- three background images, rather like conveyor belt
            bg = SKSpriteNode(texture:bgTexture)
            bg.position = CGPoint(x: bgTexture.size().width * i, y:self.frame.midY)
            bg.size.height = self.frame.height
            bg.zPosition = -1
            bg.run(moveBGForever)
            self.addChild(bg)
            i = i+1
        }
        
        birdTexture = SKTexture(imageNamed: "flappy1.png")
        let birdTexture2 = SKTexture(imageNamed:"flappy2.png")
        
        let animation = SKAction.animate(with:[birdTexture, birdTexture2], timePerFrame:0.1)
        let makeBirdFlap = SKAction.repeatForever(animation)
        
        bird = SKSpriteNode(texture:birdTexture)
        
        var startingPosition = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.position = CGPoint(x: -500, y: self.frame.midY)
        bird.run(makeBirdFlap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture.size().height / 2)
        bird.physicsBody!.isDynamic = false
        
        bird.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        bird.physicsBody!.categoryBitMask = ColliderType.Bird.rawValue
        bird.physicsBody!.collisionBitMask = ColliderType.Bird.rawValue
        bird.zPosition = 20
        
        self.addChild(bird)
        
        
        let initialAction = SKAction.move(to:startingPosition, duration:1.5)
        
        self.bird.anchorPoint = CGPoint(x:0.5, y:0.5)
        self.bird.run(initialAction)
        
        
        
        
        // invisible ground
        let ground = SKNode()
        ground.position = CGPoint(x:self.frame.midX, y: -self.frame.height/2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width:self.frame.width, height:1))
        ground.physicsBody!.isDynamic = false
        
        ground.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        ground.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        ground.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        self.addChild(ground)
        
        // score label
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 60
        scoreLabel.text = "0"
        scoreLabel.zPosition = 15
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.height / 2 - 100 )
        self.addChild(scoreLabel)
    }
    
    // whenever there's a collision
    func didBegin(_ contact: SKPhysicsContact) {
        
        if (gameOver == false)
        {
            if (contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue)
                || (contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue)
            {
                
                currentScore += 1
                scoreLabel.text = String(currentScore)
                run(achievementSound)
                // remove that gap
                
                if (contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue)
                {
                    let theGap = contact.bodyA.node! as SKNode
                    self.removeChildren(in: [theGap])
                } else
                {
                        let theGap = contact.bodyB.node! as SKNode
                    self.removeChildren(in: [theGap])
                }
                
                if (currentScore % 5 == 0)
                {
                    let rotateBirdAction = SKAction.rotate(byAngle: .pi*4, duration: 0.5)
                    bird.run(rotateBirdAction)
                }
                
                
                return
            }
            
            
            
            
            let burstPath = Bundle.main.path(
                forResource: "MagicParticle", ofType: "sks")
            
            if burstPath != nil {
                let burstNode =
                    NSKeyedUnarchiver.unarchiveObject(withFile: burstPath!)
                        as! SKEmitterNode
                burstNode.position = CGPoint(x: contact.contactPoint.x, y: contact.contactPoint.y+8)
                
                self.addChild(burstNode)
                run(explosionSound)
            }
            
            
            self.speed = 0 // stop the game
            gameOver = true
            bird.physicsBody?.isDynamic = false
            
            timer.invalidate() // stop the generation of new ticks
            gameOverLabel.fontName = "Helvetica"
            gameOverLabel.fontSize = 40
            gameOverLabel.text = "Game Over!"
            gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
            gameOverLabel.zPosition = 10
            
            self.bird.physicsBody?.isDynamic = true
            self.bird.physicsBody?.friction = 1
            self.speed = 0.2
            self.bird.physicsBody!.allowsRotation = true
            
            let rotateAction = SKAction.rotate(byAngle:.pi*6, duration:0.4)
            self.bird.anchorPoint = CGPoint(x:0.5, y:0.5)
            self.bird.run(rotateAction)
            
            shakeCamera(duration:2)
            
            self.addChild(gameOverLabel)
            
            self.readyForNewGame = false
            
            endOfGameTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(3), repeats: false, block: { (_) in
                //self.burstNode.removeFromParent()
                
                
                
                
                self.readyForNewGame = true
                self.gameOverLabel.text = "Tap to play again."
                
                
                
            })
            
            
        }
        
    }
    
    
    func shakeCamera(duration:Float) {
        let amplitudeX:Float = 10;
        let amplitudeY:Float = 6;
        let numberOfShakes = duration / 0.04;
        var actionsArray:[SKAction] = [];
        for _ in 1...Int(numberOfShakes) {
            // build a new random shake and add it to the list
            let moveX = Float(arc4random_uniform(UInt32(amplitudeX))) - amplitudeX / 2;
            let moveY = Float(arc4random_uniform(UInt32(amplitudeY))) - amplitudeY / 2;
            let shakeAction = SKAction.moveBy(x: CGFloat(moveX), y: CGFloat(moveY), duration: 0.02);
            shakeAction.timingMode = SKActionTimingMode.easeOut;
            actionsArray.append(shakeAction);
            actionsArray.append(shakeAction.reversed());
        }
        
        let actionSeq = SKAction.sequence(actionsArray);
        bg.run(actionSeq);
    }
    
    
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        if (gameOver == false)
        {
            bird.physicsBody!.velocity = CGVector(dx:0, dy:0)
            bird.physicsBody!.applyImpulse(CGVector(dx:0, dy:impulseAmount))
            bird.physicsBody!.isDynamic = true
        }
        else // game is over, let's reset the game after a delay
        {
            
            if (self.readyForNewGame==true)
            {
                
                    self.gameOver = false
                    self.timer.invalidate()
                    
                    self.currentScore = 0
                    self.speed = 1
                    self.removeAllChildren()
                    self.setupGame()
                
                
            
            }
            
            
            
            
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        
        
        
    }
}
