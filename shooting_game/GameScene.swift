//
//  GameScene.swift
//  shooting_game
//
//  Created by 佐藤利紀 on 2020/05/07.
//  Copyright © 2020 Yoshiki Sato. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // 背景
    var haikei: SKSpriteNode!
    // スペースシップ
    var spaceship: SKSpriteNode!
    // ハート
    var hearts: [SKSpriteNode] = []
    var scoreLabel: SKLabelNode!
    var gameVC: GameViewController!
    
    var accelaration: CGFloat = 0.0
    
    var timer: Timer?
    
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    let spaceshipCategory: UInt32 = 0b0001
    let missileCategory: UInt32 = 0b0010
    let asteroidCategory: UInt32 = 0b0100
    let earthCategory: UInt32 = 0b1000
    
    // ステージ番号
    var stageCnt:  Int = 1
    let stageNo = UILabel()
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        // 背景
        self.haikei = SKSpriteNode(imageNamed: "galaxy")
        //self.haikei.xScale = 1.5
        //self.haikei.yScale = 0.3
        //self.haikei.position = CGPoint(x:0,y: -frame.height / 2)
        self.haikei.size = self.size
        self.haikei.zPosition = -1.0
        
        self.haikei.physicsBody?.categoryBitMask = earthCategory
        self.haikei.physicsBody?.contactTestBitMask = asteroidCategory
        self.haikei.physicsBody?.collisionBitMask = 0
        addChild(self.haikei)
        

        
        // スペースシップ
        self.spaceship = SKSpriteNode(imageNamed: "spaceship")
        self.spaceship.scale(to: CGSize(width: frame.width / 5, height: frame.width / 5))
        self.spaceship.position = CGPoint(x: 0, y: -self.size.height/4.0)
        self.spaceship.physicsBody = SKPhysicsBody(circleOfRadius: self.spaceship.frame.width * 0.1)
        self.spaceship.physicsBody?.categoryBitMask = spaceshipCategory
        self.spaceship.physicsBody?.contactTestBitMask = asteroidCategory
        self.spaceship.physicsBody?.collisionBitMask = 0
        addChild(self.spaceship)
        
        // 敵キャラ出現
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.addEnemy(sts: 1)
        })
        // ハートの数指定
        for i in 1...3 {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.position = CGPoint(x: -frame.width / 2 + heart.frame.height * CGFloat(i), y: frame.height / 2 - heart.frame.height)
            addChild(heart)
            hearts.append(heart)
        }
        
        // スコアラベル
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "Papyrus"
        scoreLabel.fontSize = 50
        scoreLabel.position = CGPoint(x: -frame.width / 2 + scoreLabel.frame.width / 2 + 60, y: frame.height / 2 - scoreLabel.frame.height * 5)
        addChild(scoreLabel)
        
        // ステージナンバーの設定
        stageNo.textColor = UIColor.white
        stageNo.font = UIFont.systemFont(ofSize: 30)
    }
    
    override func didSimulatePhysics() {
        let nextPosition = self.spaceship.position.x + self.accelaration * 50
        if nextPosition > frame.width / 2 - 30 { return }
        if nextPosition < -frame.width / 2 + 30 { return }
        self.spaceship.position.x = nextPosition
        
    }
    
    // 敵を出現させる
    func addEnemy(sts: Int) {
        let names = ["enemy1", "asteroid2", "asteroid3"]
        let index = Int(arc4random_uniform(UInt32(names.count)))
        let name = names[index]
        let enemy = SKSpriteNode(imageNamed: name)
        if sts == 0 {
            let remove = SKAction.removeFromParent()
            enemy.run(SKAction.sequence([remove]))
        } else {
            let random = CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)
            let positionX = frame.width * (random - 0.5)
            enemy.position = CGPoint(x: positionX, y: frame.height / 2 + enemy.frame.height)
            enemy.scale(to: CGSize(width: 70, height: 70))
            enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.frame.width)
            enemy.physicsBody?.categoryBitMask = asteroidCategory
            enemy.physicsBody?.contactTestBitMask = missileCategory + spaceshipCategory + earthCategory
            enemy.physicsBody?.collisionBitMask = 0
            addChild(enemy)
            
            let move = SKAction.moveTo(y: -frame.height / 2 - enemy.frame.height, duration: 6.0)
            let remove = SKAction.removeFromParent()
            enemy.run(SKAction.sequence([move, remove]))
        }
        
    }
    
    // 衝突処理
    func didBegin(_ contact: SKPhysicsContact) {
        var asteroid: SKPhysicsBody
        var target: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask == asteroidCategory {
            asteroid = contact.bodyA
            target = contact.bodyB
        } else {
            asteroid = contact.bodyB
            target = contact.bodyA
        }
        
        guard let asteroidNode = asteroid.node else { return }
        guard let targetNode = target.node else { return }
        // 爆発の演出
        guard let explosion = SKEmitterNode(fileNamed: "Explosion") else { return }
        
        if target.categoryBitMask == spaceshipCategory || target.categoryBitMask == missileCategory {
           explosion.position = asteroidNode.position
           addChild(explosion)
        }
        
        asteroidNode.removeFromParent()
        
        // ミサイル衝突処理
        if target.categoryBitMask == missileCategory {
            targetNode.removeFromParent()
            
            // スコアアップ
            score += 5
            
            // ステージアップ
            if score % 50 == 0 {
                
                var stageTimer: Timer?
                // ステージ数カウントアップ
                stageCnt += 1
            
                stageNo.frame = CGRect(x:150, y:200, width:160, height:30)
                stageNo.text = "ステージ" + String(stageCnt)
                self.view?.addSubview(stageNo)
                                
                // 敵出現のタイマー停止
                self.timer?.invalidate()
                
                
                stageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { _ in
                    self.stageNo.text = ""
                    // 敵キャラ出現
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
                        self.addEnemy(sts: 1)
                    })

                })
            }
            
        }
                
        self.run(SKAction.wait(forDuration: 1.0)) {
            explosion.removeFromParent()
        }
        if target.categoryBitMask == spaceshipCategory {
            guard let heart = hearts.last else { return }
            heart.removeFromParent()
            hearts.removeLast()
            if hearts.isEmpty {
                gameOver()
            }
        }
    }
    
    // ゲームオーバー
    func gameOver() {
        isPaused = true
        timer?.invalidate()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.gameVC.dismiss(animated: true, completion: nil)
        }
    }
    
    // ドラッグを感知した際に呼ばれるメソッド.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //タッチした座標を取得する。
        let location = touches.first!.location(in: self)
        
        //タッチした位置まで移動するアクションを作成する。
        let action = SKAction.move(to: CGPoint(x:location.x, y:location.y + 20), duration:0.1)
        
        //アクションを実行する。
        spaceship.run(action)
    }
    
    // 指が離れたことを感知した際に呼ばれるメソッド.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPaused { return }
        let missile = SKSpriteNode(imageNamed: "missile")
        missile.position = CGPoint(x: self.spaceship.position.x, y: self.spaceship.position.y + 50)
        addChild(missile)
        missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.frame.height / 2)
        missile.physicsBody?.categoryBitMask = missileCategory
        missile.physicsBody?.contactTestBitMask = asteroidCategory
        missile.physicsBody?.collisionBitMask = 0
        
        let moveToTop = SKAction.moveTo(y: frame.height + 10, duration: 0.3)
        let remove = SKAction.removeFromParent()
        missile.run(SKAction.sequence([moveToTop, remove]))
    }
    
}
