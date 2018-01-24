//
//  StartButtonNode.swift
//  FlappsieBird
//
//  Created by Steve Murch on 1/17/18.
//  Copyright © 2018 Steve Murch. All rights reserved.
//

import UIKit
import SpriteKit

class StartButtonNode: SKSpriteNode {

    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        print("initialized StartButtonNode x")
       
        self.texture = texture
        
        self.zPosition = 100
        self.isUserInteractionEnabled = true
        
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("TOUCHES BEGAN")
            }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "start_button_clicked")))
        
        print("touches Ended")
    }
}
