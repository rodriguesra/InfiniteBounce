//
//  GameScene.swift
//  InfiniteBounce
//
//  Created by Rafael Rodrigues on 27/09/22.
//

import SpriteKit

enum GameState {
    case waiting, bouncing, advancing, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let ballLauncher = SKSpriteNode(imageNamed: "ball")
    var state = GameState.waiting
    
    let sounds = (1...22).map { SKAction.playSoundFileNamed("\($0).wav", waitForCompletion: false) }
    var scoreFromCurrentBall = 0
    var score = 0
    
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.insetBy(dx: 0, dy: -200))
        physicsWorld.contactDelegate = self
        
        ballLauncher.xScale = 0.5
        ballLauncher.yScale = 0.5
        ballLauncher.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        addChild(ballLauncher)
        
        advance()
    }
    
    func launchBall(towards location: CGPoint) {
        let angle = atan2(location.y - ballLauncher.position.y, location.x - ballLauncher.position.x)
        let y = sin(angle) * 1000
        let x = cos(angle) * 1000

        let ball = ballLauncher.copy() as! SKSpriteNode
        ball.name = "Ball"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        ball.physicsBody?.velocity = CGVector(dx: x, dy: y)
        ball.physicsBody?.linearDamping = 0
        ball.isHidden = false
        addChild(ball)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .waiting:
            guard let location = touches.first?.location(in: self) else { return }
            scoreFromCurrentBall = 0
            launchBall(towards: location)
            ballLauncher.isHidden = true
            state = .bouncing
            
        default:
            break
        }
    }
    
    func resetLauncher() {
        ballLauncher.isHidden = false
        state = .waiting
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard state == .bouncing else { return }
        
        for child in children {
            if child.position.y < frame.minY - 50 {
                child.removeFromParent()
            }
        }
        
        let hasActiveBalls = children.contains { $0.name == "Ball" }
        
        if hasActiveBalls == false {
            advance()
        }
    }
    
    func createBouncer() {
        let numberToCreate = 1
        
        for i in 0..<numberToCreate {
            let bounceCount: Int
            bounceCount = 1
            
            let bouncer = BouncerNode(bounceCount: bounceCount)
            bouncer.position = CGPoint(x: Double.random(in: -200...200), y: frame.minY - 50)
            bouncer.physicsBody = SKPhysicsBody(circleOfRadius: 32)
            bouncer.physicsBody?.contactTestBitMask = 1
            bouncer.physicsBody?.restitution = 0.75
            bouncer.physicsBody?.isDynamic = false
            bouncer.name = "Bouncer"
            addChild(bouncer)
        }
    }
    
    func advance() {
        state = .advancing
        createBouncer()
        
        let bouncers = children.filter { $0.name == "Bouncer" }
        
        let movement = SKAction.moveBy(x: 0, y: 100, duration: 0.5)
        movement.timingMode = .easeInEaseOut
        
        for child in bouncers {
            child.run(movement)
        }
        
        let checkForEnd = SKAction.run {
            self.resetLauncher()
        }
        
        run(SKAction.sequence([.wait(forDuration: 0.5), checkForEnd]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "Ball" {
            collision(between: nodeA, and: nodeB)
        } else if nodeB.name == "Ball" {
            collision(between: nodeB, and: nodeA)
        }
    }
    
    func collision(between ball: SKNode, and bouncer: SKNode) {
        guard let bouncer = bouncer as? BouncerNode else { return }
        
        bouncer.hit()
        score += 1
        
        if scoreFromCurrentBall < 22 {
            scoreFromCurrentBall += 1
        }
        
        run(sounds[scoreFromCurrentBall - 1])
    }
}
