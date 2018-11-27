//
//  ViewController.swift
//  s2ar
//
//  Created by Junya Ishihara on 2018/09/03.
//  Copyright © 2018年 Junya Ishihara. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SocketIO
import MultipeerConnectivity

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    let manager = SocketManager(socketURL: URL(string: "http://s2ar-helper.glitch.me")!, config: [.log(true), .compress])
    var settingOrigin: Bool = true
    
    var xAxisNode: SCNNode!
    var yAxisNode: SCNNode!
    var zAxisNode: SCNNode!
    var originPosition: SCNVector3!
    
    var cubeNode: SCNNode!
    var cubeNodes: [String:SCNNode] = [:]
    var cubeNodes2: [String:SCNNode] = [:]
    var cubeNodes3: [String:SCNNode] = [:]
    var lightNodes: [String:SCNNode] = [:]
    var data_all_cubes: [String] = []
    
    var lightNode: SCNNode!
    var backLightNode: SCNNode!
    
    var planeNode: SCNNode!
    var planeNodes: [UUID:SCNNode] = [:]
    
    var red: Int = 255
    var green: Int = 255
    var blue: Int = 255
    var alpha: Float = 1.0
    var basicShape: String = "cube"
    
    var roomId: String = "0000 0000"
    var CUBE_SIZE: Float = 0.01
    
    var timer = Timer()
    
    var connectionState: Bool = false
    
    var Enable_show_message: Bool = true
    
    var layer: String = "1"
    var layerChanged: Bool = false
    var lightChanged: Bool = false
    
    var world_origin: simd_float4x4!
    
    @IBOutlet var roomIDLabel: UILabel!
    @IBOutlet var togglePlanesButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var sendMapButton: UIButton!
    @IBOutlet weak var mappingStatusLabel: UILabel!
    @IBOutlet weak var sessionInfoView: UIVisualEffectView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var multipeerButton: UIButton!
    @IBOutlet weak var receivingStatusLabel: UILabel!
    
    var multipeerSession: MultipeerSession!
    var cubes: [String] = []//received_data
    var sender_id: NSObject!//MCPeerID
    var receive_mode: Bool = false
    var multipeerState : Bool = false
    
    @IBAction func multipeerButtonTapped(_ sender: UIButton) {
        if !multipeerState {
            multipeerState = true
            sendMapButton.isHidden = false
            mappingStatusLabel.isHidden = false
            multipeerButton.titleLabel?.numberOfLines = 0
            multipeerButton.setTitle("Multipeer OFF".localized, for: .normal)
            multipeerButton.setTitleColor(UIColor.red, for: .normal)
            multipeerSession.startSession()
        } else {
            multipeerState = false
            sendMapButton.isHidden = true
            mappingStatusLabel.isHidden = true
            multipeerButton.setTitle("Multipeer".localized, for: .normal)
            multipeerButton.setTitleColor(UIColor.blue, for: .normal)
            multipeerSession.stopSession()
        }
    }
    
    
    func showMessage(text: String) {
        if Enable_show_message {
            self.roomIDLabel.isHidden = false
            self.roomIDLabel.text = " " + text + " "
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Put your code which should be executed with a delay here
                if self.connectionState {
                    self.roomIDLabel.isHidden = true
                } else {
                    self.roomIDLabel.text = " ID: " + self.roomId + " "
                }
            }
        }
    }
    
    func changeCubeSize(magnification: Float) {
        self.showMessage(text: "Resize x ".localized + String(magnification))
        CUBE_SIZE = round(0.01 * magnification * 1000.0) / 1000.0
    }
    
    func changeLight(x: Float, y: Float, z: Float, intensity: Float) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        lightChanged = true
        lightNode?.removeFromParentNode()
        backLightNode?.removeFromParentNode()
        
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        let _intensity: Int = intensity < 0 ? -Int(intensity) : Int(intensity)
        
        let light = LightNode(intensity: _intensity)
        light.position = SCNVector3Make(originPosition.x + _x * CUBE_SIZE,
                                        originPosition.y + _y * CUBE_SIZE,
                                        originPosition.z + _z * CUBE_SIZE)
        lightNodes[String(_x) + "_" + String(_y) + "_" + String(_z)] = light
        //multiuser
        data_all_cubes.append(String(_x) + "_" + String(_y) + "_" + String(_z) + "_" + String(_intensity))
        
        if lightNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) {
            // remove lights if contains
            lightNodes[String(_x) + "_" + String(_y) + "_" + String(_z)]?.removeFromParentNode()
            sceneView.scene.rootNode.addChildNode(light)
        } else {
            sceneView.scene.rootNode.addChildNode(light)
        }
        
    }
    
    func setCube(x: Float, y: Float, z: Float) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        // 3Dモデル作成のデータ（.ply）は整数のみではなく 0.5 を含むため、setCube を 0.5 刻みで置けるように改造した。
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        
        func setCubeMethod(x: Float, y: Float, z: Float) {
            switch basicShape {
            case "cube":
                cubeNode = CubeNode(CUBE_SIZE: CUBE_SIZE, red: red, green: green, blue: blue, alpha: alpha)
            case "sphere":
                cubeNode = SphereNode(CUBE_SIZE: CUBE_SIZE, red: red, green: green, blue: blue, alpha: alpha)
            case "cylinder":
                cubeNode = CylinderNode(CUBE_SIZE: CUBE_SIZE, red: red, green: green, blue: blue, alpha: alpha)
            case "cone":
                cubeNode = ConeNode(CUBE_SIZE: CUBE_SIZE, red: red, green: green, blue: blue, alpha: alpha)
            case "pyramid":
                cubeNode = PyramidNode(CUBE_SIZE: CUBE_SIZE, red: red, green: green, blue: blue, alpha: alpha)
            default:
                cubeNode = CubeNode(CUBE_SIZE: CUBE_SIZE, red: red, green: green, blue: blue, alpha: alpha)
            }
            let position = SCNVector3Make(
                originPosition.x + (_x + 0.5) * CUBE_SIZE,
                originPosition.y + (_y + 0.5) * CUBE_SIZE,
                originPosition.z + (_z + 0.5) * CUBE_SIZE
            )
            cubeNode.position = position
            sceneView.scene.rootNode.addChildNode(cubeNode)
            
            //multiuser
            data_all_cubes.append(String(_x) + "_" + String(_y) + "_" + String(_z) + "_" + String(red) + "_" + String(green) + "_" + String(blue) + "_" + String(alpha) + "_" + String(CUBE_SIZE/0.01) + "_" + basicShape)
            
            switch layer {
            case "2":
                cubeNodes2[String(_x) + "_" + String(_y) + "_" + String(_z)] = cubeNode
            case "3":
                cubeNodes3[String(_x) + "_" + String(_y) + "_" + String(_z)] = cubeNode
            default:
                cubeNodes[String(_x) + "_" + String(_y) + "_" + String(_z)] = cubeNode
            }
            
        }
        if cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes2.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes3.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) {
            // remove cube if contains
            self.removeCube(x: _x, y: _y, z: _z)
            setCubeMethod(x: _x, y: _y, z: _z)
        } else {
            // set cube
            setCubeMethod(x: _x, y: _y, z: _z)
        }
    }
    
    func setBox(x: Float, y: Float, z: Float, w: Float, d: Float, h: Float) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        var _w: Float = round(2.0 * w) / 2.0
        var _d: Float = round(2.0 * d) / 2.0
        var _h: Float = round(2.0 * h) / 2.0
        var w_half: Bool = false// With 0.5
        var d_half: Bool = false// With 0.5
        var h_half: Bool = false// With 0.5
        var w_plus: Bool = true// plus or minus
        var d_plus: Bool = true// plus or minus
        var h_plus: Bool = true// plus or minus
        
        if _w < 0 {
            w_plus = false
            _w = -_w
        }
        if _d < 0 {
            d_plus = false
            _d = -_d
        }
        if _h < 0 {
            h_plus = false
            _h = -_h
        }
        
        if !(abs(_w.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            // With decimal point
            w_half = true
        }
        if !(abs(_d.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            // With decimal point
            d_half = true
        }
        if !(abs(_h.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            // With decimal point
            h_half = true
        }
        
        
        for k in 0..<Int(_d) {
            for j in 0..<Int(_h) {
                for i in 0..<Int(_w) {
                    if k == 0 || k == Int(_d) - 1 || j == 0 || j == Int(_h) - 1 || i == 0 || i == Int(_w) - 1 {
                        if w_plus && h_plus && d_plus {//ok
                            self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                        }
                        if !w_plus && h_plus && d_plus {//ok
                            self.setCube(x: _x - Float(i), y: _y + Float(j), z: _z + Float(k))
                        }
                        if w_plus && !h_plus && d_plus {
                            self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z + Float(k))
                        }
                        if w_plus && h_plus && !d_plus {
                            self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - Float(k))
                        }
                        if !w_plus && !h_plus && d_plus {
                            self.setCube(x: _x - Float(i), y: _y - Float(j), z: _z + Float(k))
                        }
                        if w_plus && !h_plus && !d_plus {
                            self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z - Float(k))
                        }
                        if !w_plus && h_plus && !d_plus {
                            self.setCube(x: _x - Float(i), y: _y + Float(j), z: _z - Float(k))
                        }
                        if !w_plus && !h_plus && !d_plus {
                            self.setCube(x: _x - Float(i), y: _y - Float(j), z: _z - Float(k))
                        }
                        if i == Int(_w) - 1 {
                            if w_half {//ok
                                if w_plus && h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + Float(j), z: _z + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 -  Float(i), y: _y + Float(j), z: _z + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - Float(j), z: _z + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + Float(j), z: _z - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 -  Float(i), y: _y - Float(j), z: _z + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - Float(j), z: _z - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 -  Float(i), y: _y + Float(j), z: _z - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 -  Float(i), y: _y - Float(j), z: _z - Float(k))
                                }
                            }
                        }
                        if j == Int(_h) - 1 {
                            if h_half {//ok
                                if w_plus && h_plus && d_plus {
                                    self.setCube(x: _x + Float(i), y: _y + 0.5 + Float(j), z: _z + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - Float(i), y: _y + 0.5 + Float(j), z: _z + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + Float(i), y: _y - 0.5 - Float(j), z: _z + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + Float(i), y: _y + 0.5 + Float(j), z: _z - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - Float(i), y: _y - 0.5 - Float(j), z: _z + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + Float(i), y: _y - 0.5 - Float(j), z: _z - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - Float(i), y: _y + 0.5 + Float(j), z: _z - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - Float(i), y: _y - 0.5 - Float(j), z: _z - Float(k))
                                }
                            }
                        }
                        if k == Int(_d) - 1 {
                            if d_half {//ok
                                if w_plus && h_plus && d_plus {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - Float(i), y: _y + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - Float(i), y: _y - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - Float(i), y: _y + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - Float(i), y: _y - Float(j), z: _z - 0.5 - Float(k))
                                }
                            }
                        }
                        if i == Int(_w) - 1 && j == Int(_h) - 1 {
                            if w_half && h_half {//ok
                                if w_plus && h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + 0.5 + Float(j), z: _z + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y + 0.5 + Float(j), z: _z + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - 0.5 - Float(j), z: _z + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + 0.5 + Float(j), z: _z - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y - 0.5 - Float(j), z: _z + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - 0.5 - Float(j), z: _z - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y + 0.5 + Float(j), z: _z - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y - 0.5 - Float(j), z: _z - Float(k))
                                }
                            }
                        }
                        if j == Int(_h) - 1 && k == Int(_d) - 1 {
                            if h_half && d_half {//ok
                                if w_plus && h_plus && d_plus {
                                    self.setCube(x: _x + Float(i), y: _y + 0.5 + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - Float(i), y: _y + 0.5 + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + Float(i), y: _y - 0.5 - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + Float(i), y: _y + 0.5 + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - Float(i), y: _y - 0.5 - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + Float(i), y: _y - 0.5 - Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - Float(i), y: _y + 0.5 + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - Float(i), y: _y - 0.5 - Float(j), z: _z - 0.5 - Float(k))
                                }
                            }
                        }
                        if k == Int(_d) - 1 && i == Int(_w) - 1 {
                            if d_half && w_half {//ok
                                if w_plus && h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y - Float(j), z: _z - 0.5 - Float(k))
                                }
                            }
                        }
                        if i == Int(_w) - 1 && j == Int(_h) - 1 && k == Int(_d) - 1 {
                            if w_half && h_half && d_half {
                                if w_plus && h_plus && d_plus {//ok
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + 0.5 + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if !w_plus && h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y + 0.5 + Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - 0.5 - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y + 0.5 + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y - 0.5 - Float(j), z: _z + 0.5 + Float(k))
                                }
                                if w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x + 0.5 + Float(i), y: _y - 0.5 - Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y + 0.5 + Float(j), z: _z - 0.5 - Float(k))
                                }
                                if !w_plus && !h_plus && !d_plus {
                                    self.setCube(x: _x - 0.5 - Float(i), y: _y - 0.5 - Float(j), z: _z - 0.5 - Float(k))
                                }
                                showMessage(text: "End to set a box".localized)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setCylinder(x: Float, y: Float, z: Float, r: Float, h: Float, a: String) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        var _h: Float = round(2.0 * h) / 2.0
        var r1: Float = round(2.0 * r) / 2.0
        var h_half: Bool = false// With 0.5
        var h_plus: Bool = true// plus or minus
        r1 = r1 < 0 ? -r1 : r1
        let _r: Int = Int(r1)
        
        if _h < 0 {
            h_plus = false
            _h = -_h
        }
        
        if !(abs(_h.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            // With decimal point
            h_half = true
        }
        
        if (abs(r1.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            //小数点なし
            switch a {
            case "x":
                for k in -_r..._r {
                    for j in -_r..._r {
                        if j * j + k * k < _r * _r {
                            self.setCube(x: _x, y: _y + Float(j), z: _z + Float(k))
                            if _h == 1.5 {
                                if h_plus {
                                    self.setCube(x: _x + 0.5, y: _y + Float(j), z: _z + Float(k))
                                } else {
                                    self.setCube(x: _x - 0.5, y: _y + Float(j), z: _z + Float(k))
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 1 {
                    for k in -_r..._r {
                        for j in -_r..._r {
                            if j * j + k * k < _r * _r {
                                if h_plus {
                                    self.setCube(x: _x + Float(Int(_h) - 1), y: _y + Float(j), z: _z + Float(k))
                                    if h_half {
                                        self.setCube(x: _x + Float(Int(_h) - 1) + 0.5, y: _y + Float(j), z: _z + Float(k))
                                    }
                                } else {
                                    self.setCube(x: _x - Float(Int(_h) - 1), y: _y + Float(j), z: _z + Float(k))
                                    if h_half {
                                        self.setCube(x: _x - Float(Int(_h) - 1) - 0.5, y: _y + Float(j), z: _z + Float(k))
                                    }
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 2 {
                    for i in 1..<Int(_h)-1 {
                        for k in -_r..._r {
                            for j in -_r..._r {
                                if (j * j + k * k < _r * _r) && (j * j + k * k >= (_r - 1) * (_r - 1)) {
                                    if h_plus {
                                        self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                                    } else {
                                        self.setCube(x: _x - Float(i), y: _y + Float(j), z: _z + Float(k))
                                    }
                                }
                            }
                        }
                    }
                    
                }
            case "y":
                for k in -_r..._r {
                    for i in -_r..._r  {
                        if i * i + k * k < _r * _r {
                            self.setCube(x: _x + Float(i), y: _y, z: _z + Float(k))
                            if _h == 1.5 {
                                if h_plus {
                                    self.setCube(x: _x + Float(i), y: _y + 0.5, z: _z + Float(k))
                                } else {
                                    self.setCube(x: _x + Float(i), y: _y - 0.5, z: _z + Float(k))
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 1 {
                    for k in -_r..._r {
                        for i in -_r..._r  {
                            if i * i + k * k < _r * _r {
                                if h_plus {
                                    self.setCube(x: _x + Float(i), y: _y + Float(Int(_h) - 1), z: _z + Float(k))
                                    if h_half {
                                        self.setCube(x: _x + Float(i), y: _y + Float(Int(_h) - 1) + 0.5, z: _z + Float(k))
                                    }
                                } else {
                                    self.setCube(x: _x + Float(i), y: _y - Float(Int(_h) - 1), z: _z + Float(k))
                                    if h_half {
                                        self.setCube(x: _x + Float(i), y: _y - Float(Int(_h) - 1) - 0.5, z: _z + Float(k))
                                    }
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 2 {
                    for j in 1..<Int(_h)-1 {
                        for k in -_r..._r{
                            for i in -_r..._r {
                                if (k * k + i * i < _r * _r) && (k * k + i * i >= (_r - 1) * (_r - 1)) {
                                    if h_plus {
                                        self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                                    } else {
                                        self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z + Float(k))
                                    }
                                }
                            }
                        }
                    }
                }
            case "z":
                for j in -_r..._r {
                    for i in -_r..._r {
                        if i * i + j * j < _r * _r {
                            self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z)
                            if _h == 1.5 {
                                if h_plus {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + 0.5)
                                } else {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - 0.5)
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 1 {
                    for j in -_r..._r {
                        for i in -_r..._r {
                            if i * i + j * j < _r * _r {
                                if h_plus {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(Int(_h) - 1))
                                    if h_half {
                                        self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(Int(_h) - 1) + 0.5)
                                    }
                                } else {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - Float(Int(_h) - 1))
                                    if h_half {
                                        self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - Float(Int(_h) - 1) - 0.5)
                                    }
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 2 {
                    for k in 1..<Int(_h)-1 {
                        for j in -_r..._r {
                            for i in -_r..._r {
                                if (i * i + j * j < _r * _r) && (i * i + j * j >= (_r - 1) * (_r - 1)) {
                                    if h_plus {
                                        self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                                    } else {
                                        self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z - Float(k))
                                    }
                                }
                            }
                        }
                    }
                }
            default:
                //error message
                self.showMessage(text: "Axis: x or y or z".localized)
                break
            }
        } else {
            //小数点あり
            switch a {
            case "x":
                for k in -_r..._r+1 {
                    for j in -_r..._r+1 {
                        if (Float(j) - 0.5) * (Float(j) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                            self.setCube(x: _x, y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                            if _h == 1.5 {
                                if h_plus {
                                    self.setCube(x: _x + 0.5, y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                } else {
                                    self.setCube(x: _x - 0.5, y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 1 {
                    for k in -_r..._r+1 {
                        for j in -_r..._r+1 {
                            if (Float(j) - 0.5) * (Float(j) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                                if h_plus {
                                    self.setCube(x: _x + Float(Int(_h) - 1), y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                    if h_half {
                                        self.setCube(x: _x + Float(Int(_h) - 1) + 0.5, y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                    }
                                } else {
                                    self.setCube(x: _x - Float(Int(_h) - 1), y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                    if h_half {
                                        self.setCube(x: _x - Float(Int(_h) - 1) - 0.5, y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                    }
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 2 {
                    for i in 1..<Int(_h)-1 {
                        for k in -_r..._r+1 {
                            for j in -_r..._r+1 {
                                if (Float(j) - 0.5) * (Float(j) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                                    if (Float(j) - 0.5) * (Float(j) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) >= (r1 - 1) * (r1 - 1) {
                                        if h_plus {
                                            self.setCube(x: _x + Float(i), y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                        } else {
                                            self.setCube(x: _x - Float(i), y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            case "y":
                for k in -_r..._r+1 {
                    for i in -_r..._r+1  {
                        if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                            self.setCube(x: _x + Float(i) - 0.5, y: _y, z: _z + Float(k) - 0.5)
                            if _h == 1.5 {
                                if h_plus {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y + 0.5, z: _z + Float(k) - 0.5)
                                } else {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y - 0.5, z: _z + Float(k) - 0.5)
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 1 {
                    for k in -_r..._r+1 {
                        for i in -_r..._r+1  {
                            if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                                if h_plus {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(Int(_h) - 1), z: _z + Float(k) - 0.5)
                                    if h_half {
                                        self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(Int(_h) - 1) + 0.5, z: _z + Float(k) - 0.5)
                                    }
                                } else {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y - Float(Int(_h) - 1), z: _z + Float(k) - 0.5)
                                    if h_half {
                                        self.setCube(x: _x + Float(i) - 0.5, y: _y - Float(Int(_h) - 1) - 0.5, z: _z + Float(k) - 0.5)
                                    }
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 2 {
                    for j in 1..<Int(_h)-1 {
                        for k in -_r..._r+1 {
                            for i in -_r..._r+1 {
                                if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                                    if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) >= (r1 - 1) * (r1 - 1) {
                                        if h_plus {
                                            self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j), z: _z + Float(k) - 0.5)
                                        } else {
                                            self.setCube(x: _x + Float(i) - 0.5, y: _y - Float(j), z: _z + Float(k) - 0.5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            case "z":
                for j in -_r..._r+1 {
                    for i in -_r..._r+1 {
                        if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(j) - 0.5) * (Float(j) - 0.5) < r1 * r1 {
                            self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z)
                            if _h == 1.5 {
                                if h_plus {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z + 0.5)
                                } else {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z - 0.5)
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 1 {
                    for j in -_r..._r+1 {
                        for i in -_r..._r+1 {
                            if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(j) - 0.5) * (Float(j) - 0.5) < r1 * r1 {
                                if h_plus {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z + Float(Int(_h) - 1))
                                    if h_half {
                                        self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z + Float(Int(_h) - 1) + 0.5)
                                    }
                                } else {
                                    self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z - Float(Int(_h) - 1))
                                    if h_half {
                                        self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z - Float(Int(_h) - 1) - 0.5)
                                    }
                                }
                            }
                        }
                    }
                }
                if Int(_h) > 2 {
                    for k in 1..<Int(_h)-1 {
                        for j in -_r..._r+1 {
                            for i in -_r..._r+1 {
                                if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(j) - 0.5) * (Float(j) - 0.5) < r1 * r1 {
                                    if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(j) - 0.5) * (Float(j) - 0.5) >= (r1 - 1) * (r1 - 1) {
                                        if h_plus {
                                            self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z + Float(k))
                                        } else {
                                            self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z - Float(k))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            default:
                //error message
                self.showMessage(text: "Axis: x or y or z".localized)
                break
            }
        }
    }
    
    func setHexagon(x: Float, y: Float, z: Float, r: Float, h: Float, a: String) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        var _h: Float = round(2.0 * h) / 2.0
        var h_half: Bool = false// With 0.5
        var h_plus: Bool = true// plus or minus
        let _r = r < 0 ? -Int(r) : Int(r)
        
        if _h < 0 {
            h_plus = false
            _h = -_h
        }
        
        if !(abs(_h.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            // With decimal point
            h_half = true
        }
        
        switch a {
        case "x":
            for k in -_r..._r {
                for j in -_r..._r {
                    for i in 0..<Int(_h) {
                        if ((Float(j) <= cos(Float.pi / 6) * Float(_r))
                            && (Float(j) >= -cos(Float.pi / 6) * Float(_r))
                            && (Float(j) <= -tan(Float.pi / 3) * Float(k) + tan(Float.pi / 3) * Float(_r))
                            && (Float(j) <= +tan(Float.pi / 3) * Float(k) + tan(Float.pi / 3) * Float(_r))
                            && (Float(j) >= -tan(Float.pi / 3) * Float(k) - tan(Float.pi / 3) * Float(_r))
                            && (Float(j) >= +tan(Float.pi / 3) * Float(k) - tan(Float.pi / 3) * Float(_r))) {
                            if h_plus {
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                                if h_half {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y + Float(j), z: _z + Float(k))
                                }
                            } else {
                                self.setCube(x: _x - Float(i), y: _y + Float(j), z: _z + Float(k))
                                if h_half {
                                    self.setCube(x: _x - Float(i) - 0.5, y: _y + Float(j), z: _z + Float(k))
                                }
                            }
                        }
                    }
                }
            }
        case "y":
            for k in -_r..._r {
                for j in 0..<Int(_h) {
                    for i in -_r..._r {
                        if ((Float(k) <= cos(Float.pi / 6) * Float(_r))
                            && (Float(k) >= -cos(Float.pi / 6) * Float(_r))
                            && (Float(k) <= -tan(Float.pi / 3) * Float(i) + tan(Float.pi / 3) * Float(_r))
                            && (Float(k) <= +tan(Float.pi / 3) * Float(i) + tan(Float.pi / 3) * Float(_r))
                            && (Float(k) >= -tan(Float.pi / 3) * Float(i) - tan(Float.pi / 3) * Float(_r))
                            && (Float(k) >= +tan(Float.pi / 3) * Float(i) - tan(Float.pi / 3) * Float(_r))) {
                            if h_plus {
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                                if h_half {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j) + 0.5, z: _z + Float(k))
                                }
                            } else {
                                self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z + Float(k))
                                if h_half {
                                    self.setCube(x: _x + Float(i), y: _y - Float(j) - 0.5, z: _z + Float(k))
                                }
                            }
                        }
                    }
                }
            }
        case "z":
            for k in 0..<Int(_h) {
                for j in -_r..._r {
                    for i in -_r..._r {
                        if ((Float(i) <= cos(Float.pi / 6) * Float(_r))
                            && (Float(i) >= -cos(Float.pi / 6) * Float(_r))
                            && (Float(i) <= -tan(Float.pi / 3) * Float(j) + tan(Float.pi / 3) * Float(_r))
                            && (Float(i) <= +tan(Float.pi / 3) * Float(j) + tan(Float.pi / 3) * Float(_r))
                            && (Float(i) >= -tan(Float.pi / 3) * Float(j) - tan(Float.pi / 3) * Float(_r))
                            && (Float(i) >= +tan(Float.pi / 3) * Float(j) - tan(Float.pi / 3) * Float(_r))) {
                            if h_plus {
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                                if h_half {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k) + 0.5)
                                }
                            } else {
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - Float(k))
                                if h_half {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z - Float(k) - 0.5)
                                }
                            }
                        }
                    }
                }
            }
        default:
            //error message
            self.showMessage(text: "Axis: x or y or z".localized)
            break
        }
    }
    
    func setSphere(x: Float, y: Float, z: Float, r: Float) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        let r1: Float = round(2.0 * r) / 2.0
        let _r = r1 < 0 ? -Int(r1) : Int(r1)
        
        if (abs(r1.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            //小数点なし
            for k in -_r..._r {
                for j in -_r..._r {
                    for i in -_r..._r {
                        if i * i + j * j + k * k < _r * _r {
                            if i * i + j * j + k * k >= (_r - 1) * (_r - 1) {
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(k))
                            }
                        }
                    }
                }
            }
        } else {
            //小数点あり
            for k in -_r..._r+1 {
                for j in -_r..._r+1 {
                    for i in -_r..._r+1 {
                        if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(j) - 0.5) * (Float(j) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) < r1 * r1 {
                            if (Float(i) - 0.5) * (Float(i) - 0.5) + (Float(j) - 0.5) * (Float(j) - 0.5) + (Float(k) - 0.5) * (Float(k) - 0.5) > (r1 - 1) * (r1 - 1) {
                                self.setCube(x: _x + Float(i) - 0.5, y: _y + Float(j) - 0.5, z: _z + Float(k) - 0.5)
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    func setChar(x: Float, y: Float, z: Float, c: String, a: String) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        var k = 0
        let char:String! = Chars.chars[c]
        
        if char == nil {
            showMessage(text: "Invalid character".localized)
        } else {
            switch (a) {
            case "x":
                for j in 0..<8 {
                    for i in 0..<8 {
                        var flag = char[char.index(char.startIndex, offsetBy: k)..<char.index(char.startIndex, offsetBy: k + 1)]
                        if (flag == "1") {
                            self.setCube(x: _x, y: _y - Float(j), z: _z + Float(i))
                        }
                        k += 1
                    }
                }
            case "y":
                for j in 0..<8 {
                    for i in 0..<8 {
                        var flag = char[char.index(char.startIndex, offsetBy: k)..<char.index(char.startIndex, offsetBy: k + 1)]
                        if (flag == "1") {
                            self.setCube(x: _x + Float(i), y: _y, z: _z + Float(j))
                        }
                        k += 1
                    }
                }
            case "z":
                for j in 0..<8 {
                    for i in 0..<8 {
                        var flag = char[char.index(char.startIndex, offsetBy: k)..<char.index(char.startIndex, offsetBy: k + 1)]
                        if (flag == "1") {
                            self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z)
                        }
                        k += 1
                    }
                }
            default:
                //error message
                self.showMessage(text: "Axis: x or y or z".localized)
                break
            }
        }
    }
    
    func setLine(x1: Float, y1: Float, z1: Float, x2: Float, y2: Float, z2: Float) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        self.showMessage(text: "Set a line".localized)
        
        let _x1: Float = round(2.0 * x1) / 2.0
        let _y1: Float = round(2.0 * y1) / 2.0
        let _z1: Float = round(2.0 * z1) / 2.0
        let _x2: Float = round(2.0 * x2) / 2.0
        let _y2: Float = round(2.0 * y2) / 2.0
        let _z2: Float = round(2.0 * z2) / 2.0
        
        if !(_x1 == _x2 && _y1 == _y2 && _z1 == _z2) {
            var vector = [_x2 - _x1, _y2 - _y1, _z2 - _z1]
            var vector2 = [abs(_x2 - _x1), abs(_y2 - _y1), abs(_z2 - _z1)]
            var _x: Float
            var _y: Float
            var _z: Float
            
            let index:Int? = vector2.index(of: vector2.max()!)
            
            switch (index) {
            case 0:
                for i in 0...Int(vector2[0]) {
                    if (_x2 > _x1) {
                        _x = Float(_x1) + Float(i)
                        _y = Float(_y1) + Float(vector[1]) * Float(i) / Float(vector[0])
                        _z = Float(_z1) + Float(vector[2]) * Float(i) / Float(vector[0])
                    } else {
                        _x = Float(_x2) + Float(i)
                        _y = Float(_y2) + Float(vector[1]) * Float(i) / Float(vector[0])
                        _z = Float(_z2) + Float(vector[2]) * Float(i) / Float(vector[0])
                    }
                    _x = round(_x * 2.0) / 2.0
                    _y = round(_y * 2.0) / 2.0
                    _z = round(_z * 2.0) / 2.0
                    if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes2.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes3.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                        // does not contains key
                        self.setCube(x: _x, y: _y, z: _z)
                    }
                }
                if !(abs(vector2[2].truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
                    if !(cubeNodes.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2)) || cubeNodes2.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2)) || cubeNodes3.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2))) {
                        // does not contains key
                        self.setCube(x: _x2, y: _y2, z: _z2)
                    }
                }
            case 1:
                for i in 0...Int(vector2[1]) {
                    if (_y2 > _y1) {
                        _x = Float(_x1) + Float(vector[0]) * Float(i) / Float(vector[1])
                        _y = Float(_y1) + Float(i)
                        _z = Float(_z1) + Float(vector[2]) * Float(i) / Float(vector[1])
                    } else {
                        _x = Float(_x2) + Float(vector[0]) * Float(i) / Float(vector[1])
                        _y = Float(_y2) + Float(i)
                        _z = Float(_z2) + Float(vector[2]) * Float(i) / Float(vector[1])
                    }
                    _x = round(_x * 2.0) / 2.0
                    _y = round(_y * 2.0) / 2.0
                    _z = round(_z * 2.0) / 2.0
                    if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes2.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes3.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                        // does not contains key
                        self.setCube(x: _x, y: _y, z: _z)
                    }
                }
                if !(abs(vector2[2].truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
                    if !(cubeNodes.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2)) || cubeNodes2.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2)) || cubeNodes3.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2))) {
                        // does not contains key
                        self.setCube(x: _x2, y: _y2, z: _z2)
                    }
                }
            case 2:
                for i in 0...Int(vector2[2]) {
                    if (_z2 > _z1) {
                        _x = Float(_x1) + Float(vector[0]) * Float(i) / Float(vector[2])
                        _y = Float(_y1) + Float(vector[1]) * Float(i) / Float(vector[2])
                        _z = Float(_z1) + Float(i)
                    } else {
                        _x = Float(_x2) + Float(vector[0]) * Float(i) / Float(vector[2])
                        _y = Float(_y2) + Float(vector[1]) * Float(i) / Float(vector[2])
                        _z = Float(_z2) + Float(i)
                    }
                    _x = round(_x * 2.0) / 2.0
                    _y = round(_y * 2.0) / 2.0
                    _z = round(_z * 2.0) / 2.0
                    if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes2.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes3.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                        // does not contains key
                        self.setCube(x: _x, y: _y, z: _z)
                    }
                }
                if !(abs(vector2[2].truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
                    if !(cubeNodes.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2)) || cubeNodes2.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2)) || cubeNodes3.keys.contains(String(_x2) + "_" + String(_y2) + "_" + String(_z2))) {
                        // does not contains key
                        self.setCube(x: _x2, y: _y2, z: _z2)
                    }
                }
            default:
                break
            }
        } else {
            //error message
            self.showMessage(text: "Same points".localized)
        }
    }
    
    func setRoof(x: Float, y: Float, z: Float, w: Int, d: Float, h: Int, a: String) {// w, h の Float は後回し
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        
        var temp: Float
        var temp1: Float
        var temp2: Float
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        var _d: Float = round(2.0 * d) / 2.0
        var d_half: Bool = false// With 0.5
        _d = _d < 0 ? -_d : _d
        
        if !(abs(_d.truncatingRemainder(dividingBy: 1.0)).isLess(than: .ulpOfOne)) {
            // With decimal point
            d_half = true
        }
        
        switch (a) {
        case "x":
            if (w % 2 == 0) {
                if (abs(h) <= w / 2) {
                    for j in 0..<w {
                        if h > 0 {
                            temp1 = 2.0 * (Float(h) - 1.0) * Float(j) / (Float(w) - 2.0)
                            temp2 = 2.0 * (Float(h) - 1.0) * (Float(j) - Float(w) + 1.0) / (Float(w) - 2.0)
                        } else {
                            temp1 = 2.0 * (Float(h) + 1.0) * Float(j) / (Float(w) - 2.0)
                            temp2 = 2.0 * (Float(h) + 1.0) * (Float(j) - Float(w) + 1.0) / (Float(w) - 2.0)
                        }
                        for i in 0..<Int(_d) {
                            if (j < w / 2) {
                                self.setCube(x: _x + Float(i), y: _y + temp1, z: _z + Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y + temp1, z: _z + Float(j))
                                }
                            } else {
                                self.setCube(x: _x + Float(i), y: _y - temp2, z: _z + Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y - temp2, z: _z + Float(j))
                                    
                                }
                            }
                        }
                    }
                } else {
                    if h > 0 {
                        for j in 0..<h {
                            temp = (Float(w) - 2.0) * Float(j) / (2.0 * (Float(h) - 1.0))
                            for i in 0..<Int(_d) {
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + temp)
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(w) - temp - 1.0)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y + Float(j), z: _z + temp)
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y + Float(j), z: _z + Float(w) - temp - 1.0)
                                }
                            }
                        }
                    } else {
                        for j in 0..<(-h) {
                            temp = (Float(w) - 2.0) * Float(j) / (2.0 * (Float(h) + 1.0))
                            for i in 0..<Int(_d) {
                                self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z - temp)
                                self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z + Float(w) + temp - 1.0)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y - Float(j), z: _z - temp)
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y - Float(j), z: _z + Float(w) + temp - 1.0)
                                    
                                }
                            }
                        }
                    }
                }
            } else {
                if (abs(h) <= (w + 1) / 2) {
                    for j in 0..<w {
                        if h > 0 {
                            temp1 = 2.0 * (Float(h) - 1) * Float(j) / (Float(w) - 1.0)
                            temp2 = 2.0 * (Float(h) - 1) * (Float(j) - Float(w) + 1.0) / (Float(w) - 1.0)
                        } else {
                            temp1 = 2.0 * (Float(h) + 1) * Float(j) / (Float(w) - 1.0)
                            temp2 = 2.0 * (Float(h) + 1) * (Float(j) - Float(w) + 1.0) / (Float(w) - 1.0)
                        }
                        for i in 0..<Int(_d) {
                            if (j < w / 2) {
                                self.setCube(x: _x + Float(i), y: _y + temp1, z: _z + Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y + temp1, z: _z + Float(j))
                                }
                            } else {
                                self.setCube(x: _x + Float(i), y: _y - temp2, z: _z + Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y - temp2, z: _z + Float(j))
                                }
                            }
                        }
                    }
                } else {
                    if h > 0 {
                        for j in 0..<h {
                            for i in 0..<Int(_d) {
                                temp = (Float(w) - 1.0) * Float(j) / (2.0 * (Float(h) - 1.0))
                                self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + temp)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y + Float(j), z: _z + temp)
                                }
                                if j != h - 1 {
                                    self.setCube(x: _x + Float(i), y: _y + Float(j), z: _z + Float(w) - temp - 1.0)
                                    if d_half && i == Int(_d) - 1 {
                                        self.setCube(x: _x + Float(i) + 0.5, y: _y + Float(j), z: _z + Float(w) - temp - 1.0)
                                    }
                                }
                            }
                        }
                    } else {
                        for j in 0..<(-h) {
                            for i in 0..<Int(_d) {
                                temp = (Float(w) - 1.0) * Float(j) / (2.0 * (Float(h) + 1.0))
                                self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z - temp)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(i) + 0.5, y: _y - Float(j), z: _z - temp)
                                }
                                if j != h - 1 {
                                    self.setCube(x: _x + Float(i), y: _y - Float(j), z: _z + Float(w) + temp - 1.0)
                                    if d_half && i == Int(_d) - 1 {
                                        self.setCube(x: _x + Float(i) + 0.5, y: _y - Float(j), z: _z + Float(w) + temp - 1.0)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        case "y":
            if (w % 2 == 0) {
                if (abs(h) <= w / 2) {
                    for j in 0..<w {
                        if h > 0 {
                            temp1 = 2.0 * (Float(h) - 1.0) * Float(j) / (Float(w) - 2.0)
                            temp2 = 2.0 * (Float(h) - 1.0) * (Float(j) - Float(w) + 1.0) / (Float(w) - 2.0)
                        } else {
                            temp1 = 2.0 * (Float(h) + 1.0) * Float(j) / (Float(w) - 2.0)
                            temp2 = 2.0 * (Float(h) + 1.0) * (Float(j) - Float(w) + 1.0) / (Float(w) - 2.0)
                        }
                        for i in 0..<Int(_d) {
                            if (j < w / 2) {
                                self.setCube(x: _x + Float(j), y: _y + Float(i), z: _z + temp1)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y + Float(i) + 0.5, z: _z + temp1)
                                }
                            } else {
                                self.setCube(x: _x + Float(j), y: _y + Float(i), z: _z - temp2)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y + Float(i) + 0.5, z: _z - temp2)
                                }
                            }
                        }
                    }
                } else {
                    if h > 0 {
                        for j in 0..<h {
                            temp = (Float(w) - 2.0) * Float(j) / (2.0 * (Float(h) - 1.0))
                            for i in 0..<Int(_d) {
                                self.setCube(x: _x + temp, y: _y + Float(i), z: _z + Float(j))
                                self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(i), z: _z + Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + temp, y: _y + Float(i) + 0.5, z: _z + Float(j))
                                    self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(i) + 0.5, z: _z + Float(j))
                                }
                            }
                        }
                    } else {
                        for j in 0..<(-h) {
                            temp = (Float(w) - 2.0) * Float(j) / (2.0 * (Float(h) + 1.0))
                            for i in 0..<Int(_d) {
                                self.setCube(x: _x - temp, y: _y + Float(i), z: _z - Float(j))
                                self.setCube(x: _x + Float(w) + temp - 1.0, y: _y + Float(i), z: _z - Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x - temp, y: _y + Float(i) + 0.5, z: _z - Float(j))
                                    self.setCube(x: _x + Float(w) + temp - 1.0, y: _y + Float(i) + 0.5, z: _z - Float(j))
                                }
                            }
                        }
                    }
                }
            } else {
                if (abs(h) <= (w + 1) / 2) {
                    for j in 0..<w {
                        if h > 0 {
                            temp1 = 2.0 * (Float(h) - 1) * Float(j) / (Float(w) - 1.0)
                            temp2 = 2.0 * (Float(h) - 1) * (Float(j) - Float(w) + 1.0) / (Float(w) - 1.0)
                        } else {
                            temp1 = 2.0 * (Float(h) + 1) * Float(j) / (Float(w) - 1.0)
                            temp2 = 2.0 * (Float(h) + 1) * (Float(j) - Float(w) + 1.0) / (Float(w) - 1.0)
                        }
                        for i in 0..<Int(_d) {
                            if (j < w / 2) {
                                self.setCube(x: _x + Float(j), y: _y + Float(i), z: _z + temp1)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y + Float(i) + 0.5, z: _z + temp1)
                                }
                            } else {
                                self.setCube(x: _x + Float(j), y: _y + Float(i), z: _z - temp2)
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y + Float(i) + 0.5, z: _z - temp2)
                                }
                            }
                        }
                    }
                } else {
                    if h > 0 {
                        for j in 0..<h {
                            for i in 0..<Int(_d) {
                                let temp: Float = (Float(w) - 1.0) * Float(j) / (2.0 * (Float(h) - 1.0))
                                self.setCube(x: _x + temp, y: _y + Float(i), z: _z + Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + temp, y: _y + Float(i) + 0.5, z: _z + Float(j))
                                }
                                if j != h - 1 {
                                    self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(i), z: _z + Float(j))
                                    if d_half && i == Int(_d) - 1 {
                                        self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(i) + 0.5, z: _z + Float(j))
                                    }
                                }
                            }
                        }
                    } else {
                        for j in 0..<(-h) {
                            for i in 0..<Int(_d) {
                                let temp: Float = (Float(w) - 1.0) * Float(j) / (2.0 * (Float(h) + 1.0))
                                self.setCube(x: _x - temp, y: _y + Float(i), z: _z - Float(j))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x - temp, y: _y + Float(i) + 0.5, z: _z - Float(j))
                                }
                                if j != h - 1 {
                                    self.setCube(x: _x + Float(w) + temp - 1.0, y: _y + Float(i), z: _z - Float(j))
                                    if d_half && i == Int(_d) - 1 {
                                        self.setCube(x: _x + Float(w) + temp - 1.0, y: _y + Float(i) + 0.5, z: _z - Float(j))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        case "z":
            if (w % 2 == 0) {
                if (abs(h) <= w / 2) {
                    for j in 0..<w {
                        if h > 0 {
                            temp1 = 2.0 * (Float(h) - 1.0) * Float(j) / (Float(w) - 2.0)
                            temp2 = 2.0 * (Float(h) - 1.0) * (Float(j) - Float(w) + 1.0) / (Float(w) - 2.0)
                        } else {
                            temp1 = 2.0 * (Float(h) + 1.0) * Float(j) / (Float(w) - 2.0)
                            temp2 = 2.0 * (Float(h) + 1.0) * (Float(j) - Float(w) + 1.0) / (Float(w) - 2.0)
                        }
                        for i in 0..<Int(_d) {
                            if (j < w / 2) {
                                self.setCube(x: _x + Float(j), y: _y + temp1, z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y + temp1, z: _z + Float(i) + 0.5)
                                }
                            } else {
                                self.setCube(x: _x + Float(j), y: _y - temp2, z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y - temp2, z: _z + Float(i) + 0.5)
                                }
                            }
                        }
                    }
                } else {
                    if h > 0 {
                        for j in 0..<h {
                            temp = (Float(w) - 2.0) * Float(j) / (2.0 * (Float(h) - 1.0))
                            for i in 0..<Int(_d) {
                                self.setCube(x: _x + temp, y: _y + Float(j), z: _z + Float(i))
                                self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(j), z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + temp, y: _y + Float(j), z: _z + Float(i) + 0.5)
                                    self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(j), z: _z + Float(i) + 0.5)
                                }
                            }
                        }
                    } else {
                        for j in 0..<(-h) {
                            temp = (Float(w) - 2.0) * Float(j) / (2.0 * (Float(h) + 1.0))
                            for i in 0..<Int(_d) {
                                self.setCube(x: _x - temp, y: _y - Float(j), z: _z + Float(i))
                                self.setCube(x: _x + Float(w) + temp - 1.0, y: _y - Float(j), z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x - temp, y: _y - Float(j), z: _z + Float(i) + 0.5)
                                    self.setCube(x: _x + Float(w) + temp - 1.0, y: _y - Float(j), z: _z + Float(i) + 0.5)
                                }
                            }
                        }
                    }
                }
            } else {
                if (abs(h) <= (w + 1) / 2) {
                    for j in 0..<w {
                        if h > 0 {
                            temp1 = 2.0 * (Float(h) - 1) * Float(j) / (Float(w) - 1.0)
                            temp2 = 2.0 * (Float(h) - 1) * (Float(j) - Float(w) + 1.0) / (Float(w) - 1.0)
                        } else {
                            temp1 = 2.0 * (Float(h) + 1) * Float(j) / (Float(w) - 1.0)
                            temp2 = 2.0 * (Float(h) + 1) * (Float(j) - Float(w) + 1.0) / (Float(w) - 1.0)
                        }
                        for i in 0..<Int(_d) {
                            if (j < w / 2) {
                                self.setCube(x: _x + Float(j), y: _y + temp1, z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y + temp1, z: _z + Float(i) + 0.5)
                                }
                            } else {
                                self.setCube(x: _x + Float(j), y: _y - temp2, z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(j), y: _y - temp2, z: _z + Float(i) + 0.5)
                                }
                            }
                        }
                    }
                } else {
                    if h > 0 {
                        for j in 0..<h {
                            for i in 0..<Int(_d) {
                                temp = (Float(w) - 1.0) * Float(j) / (2.0 * (Float(h) - 1.0))
                                self.setCube(x: _x + temp, y: _y + Float(j), z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + temp, y: _y + Float(j), z: _z + Float(i) + 0.5)
                                }
                                if j != h - 1 {
                                    self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(j), z: _z + Float(i))
                                    if d_half && i == Int(_d) - 1 {
                                        self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(j), z: _z + Float(i) + 0.5)
                                    }
                                }
                            }
                        }
                    } else {
                        for j in 0..<(-h) {
                            for i in 0..<Int(_d) {
                                temp = (Float(w) - 1.0) * Float(j) / (2.0 * (Float(h) + 1.0))
                                self.setCube(x: _x - temp, y: _y - Float(j), z: _z + Float(i))
                                if d_half && i == Int(_d) - 1 {
                                    self.setCube(x: _x + Float(w) - temp - 1.0, y: _y + Float(j), z: _z + Float(i) + 0.5)
                                }
                                if j != h - 1 {
                                    self.setCube(x: _x + Float(w) + temp - 1.0, y: _y - Float(j), z: _z + Float(i))
                                    if d_half && i == Int(_d) - 1 {
                                        self.setCube(x: _x + Float(w) + temp - 1.0, y: _y - Float(j), z: _z + Float(i) + 0.5)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        default:
            //error message
            self.showMessage(text: "Axis: x or y or z".localized)
            break
        }
    }
    
    func polygonFileFormat(x: Float, y: Float, z: Float, ply_file: String) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        self.showMessage(text: "Create 3d model".localized)
        
        Enable_show_message = false// 色指定など余計なメッセージを表示させない
        
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        
        let loop: Int
        
        var ply2 = [[String]]()
        
        func createModel() throws {
            if ply2.count == 0 {
                throw NSError(domain: "Error message", code: -1, userInfo: nil)
            }
            var vertex1: [String]
            var vertex2: [String]
            var vertex3: [String]
            
            var _x1: Float
            var _y1: Float
            var _z1: Float
            
            for i in 0 ..< loop {
                vertex1 = ply2[4 * i]
                vertex2 = ply2[4 * i + 1]
                vertex3 = ply2[4 * i + 2]
                red = Int(vertex1[3])!
                green = Int(vertex1[4])!
                blue = Int(vertex1[5])!
                if vertex1[0] == vertex2[0] && vertex2[0] == vertex3[0] {// y-z plane
                    if vertex1[1] == vertex2[1] {
                        _x1 = _x + Float(vertex1[0])!
                        _y1 = _y + Float(vertex1[2])!
                        _z1 = _z - Float(vertex1[1])!
                    } else {
                        _x1 = _x + Float(vertex1[0])! - 1.0
                        _y1 = _y + Float(vertex1[2])!
                        _z1 = _z - Float(vertex1[1])!
                    }
                } else if vertex1[1] == vertex2[1] && vertex2[1] == vertex3[1] {//z-x plane
                    if vertex1[2] == vertex2[2] {
                        _x1 = _x + Float(vertex1[0])!
                        _y1 = _y + Float(vertex1[2])!
                        _z1 = _z - Float(vertex1[1])!
                    } else {
                        _x1 = _x + Float(vertex1[0])!
                        _y1 = _y + Float(vertex1[2])!
                        _z1 = _z - Float(vertex1[1])! + 1.0
                    }
                } else {//x-y plane
                    if vertex1[0] == vertex2[0] {
                        _x1 = _x + Float(vertex1[0])!
                        _y1 = _y + Float(vertex1[2])!
                        _z1 = _z - Float(vertex1[1])!
                    } else {
                        _x1 = _x + Float(vertex1[0])!
                        _y1 = _y + Float(vertex1[2])! - 1.0
                        _z1 = _z - Float(vertex1[1])!
                    }
                }
                if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes2.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z)) || cubeNodes3.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                    // does not contains key
                    self.setCube(x: _x1, y: _y1, z: _z1)
                }
            }
        }
        
        if ply_file.contains("ply") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_ply_file = dir.appendingPathComponent( ply_file )
                do {
                    let ply = try String( contentsOf: path_ply_file, encoding: String.Encoding.utf8 )
                    var plys = ply.components(separatedBy: "\r\n")
                    if plys.count == 1 {
                        plys = ply.components(separatedBy: "\n")
                    }
                    if plys.count == 1 {
                        plys = ply.components(separatedBy: "\r")
                    }
                    
                    if Int(plys[4].components(separatedBy: " ")[2]) != nil {
                        loop = Int(plys[4].components(separatedBy: " ")[2])! / 4
                        for i in 0 ..< 4 * loop {
                            ply2.append(plys[14 + i].components(separatedBy: " "))
                        }
                        try createModel()
                    } else {
                        Enable_show_message = true
                        //error message
                        self.showMessage(text: "Format error".localized)
                    }
                } catch {
                    Enable_show_message = true
                    //error messager
                    self.showMessage(text: "No such file".localized)
                }
            }
        } else {
            //read from scratch
            do {
                let plys = ply_file.components(separatedBy: " ")// separated by " " (MagicaVoxel)
                var tempArray: [String] = []
                loop = plys.count / 24
                for i in 0 ..< 4 * loop {
                    for j in 0 ..< 6 {
                        tempArray.append(plys[6 * i + j])
                    }
                    ply2.append(tempArray)
                    tempArray = []
                }
                try createModel()
            } catch {
                Enable_show_message = true
                //error message
                self.showMessage(text: "Format Error".localized)
            }
        }
        Enable_show_message = true
    }
    
    func animation(x: Float, y: Float, z: Float, differenceX: Float, differenceY: Float, differenceZ: Float, time: Double, times: Int, files: String) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        self.showMessage(text: "Animation...".localized)
        
        Enable_show_message = false// 色指定など余計なメッセージを表示させない
        
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        let _differenceX: Float = round(2.0 * differenceX) / 2.0
        let _differenceY: Float = round(2.0 * differenceY) / 2.0
        let _differenceZ: Float = round(2.0 * differenceZ) / 2.0
        
        let plys = files.components(separatedBy: ",")
        if plys[0].contains(".ply") || plys.count > 3 {
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                do {
                    for i in 0 ..< plys.count {
                        let path_ply_file = dir.appendingPathComponent( plys[i] )
                        _ = try String( contentsOf: path_ply_file, encoding: String.Encoding.utf8 )
                    }
                    var i = 0
                    timer = Timer.scheduledTimer(withTimeInterval: time, repeats: true, block: { (timer) in
                        self.polygonFileFormat(x: _x + Float(i) * _differenceX, y: _y + Float(i) * _differenceY, z: _z + Float(i) * _differenceZ, ply_file: plys[i % plys.count])
                        DispatchQueue.main.asyncAfter(deadline: .now() + time * 0.8) {
                            // Put your code which should be executed with a delay here
                            self.reset()
                        }
                        i += 1
                        if (i >= times) {
                            timer.invalidate()
                        }
                    })
                } catch {
                    Enable_show_message = true
                    //error message
                    self.showMessage(text: "No such file".localized)
                }
            }
        } else {
            Enable_show_message = true
            //error message
            self.showMessage(text: "Format error".localized)
        }
        Enable_show_message = true
    }
    
    func map(map_data: String, width: Int, height: Int, magnification: Float, r1: Int, g1: Int, b1: Int, r2: Int, g2: Int, b2: Int, upward: Int) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        self.showMessage(text: "Drawing map...".localized)
        
        Enable_show_message = false// 色指定など余計なメッセージを表示させない
        
        var map2 = [[String]]()
        var map3 = [[String]]()
        var map4 = [[Int]]()
        //map4.append([Int]())
        var maps: [String] = []
        var _maps: [String] = []
        var tempArray: [String] = []
        var tempArray2: [Int] = []
        
        func heightSetColor(y: Int, minY: Int, maxY: Int) {
            var _r: Int
            var _g: Int
            var _b: Int
            if minY == maxY {
                _r = r2
                _g = g2
                _b = b2
            } else {
                _r = Int(r1 + (y - minY) * (r2 - r1) / (maxY - minY))
                _g = Int(g1 + (y - minY) * (g2 - g1) / (maxY - minY))
                _b = Int(b1 + (y - minY) * (b2 - b1) / (maxY - minY))
                _r = _r > r2 ? r2 : _r
                _g = _g > g2 ? g2 : _g
                _b = _b > b2 ? b2 : _b
            }
            setColor(r: _r, g: _g, b: _b)
        }
        
        func drawMap(i: Int, j: Int, elevation: Int, gap: Int, minY: Int, maxY: Int, upward: Int) {
            let _x = Int(height / 2) - i
            let _y = elevation
            let _z = j - Int(width / 2)
            print("i: \(i), j: \(j), elevation: \(elevation), gap: \(gap), minY: \(minY), maxY: \(maxY), upward: \(upward)")
            if _y > 0 {
                heightSetColor(y: _y, minY: minY, maxY: maxY)
                self.setCube(x: Float(_x), y: Float(_y + upward), z: Float(_z))
                if gap < 1000 { // Not infinity
                    if gap > 1 {
                        for k in 1 ... gap - 1 {
                            heightSetColor(y: _y - k, minY: minY, maxY: maxY)
                            self.setCube(x: Float(_x), y: Float(_y - k + upward), z: Float(_z))
                        }
                    }
                }
            } else if _y < 0{
                heightSetColor(y: -_y, minY: -maxY, maxY: -minY)
                self.setCube(x: Float(_x), y: Float(_y + 1 + upward), z: Float(_z))
                if gap < 1000 { // Not infinity
                    if gap > 1 {
                        for k in 1 ... gap - 1 {
                            heightSetColor(y: -_y - k, minY: -maxY, maxY: -minY)
                            self.setCube(x: Float(_x), y: Float(_y + 1 + k + upward), z: Float(_z))
                        }
                    }
                }
            }
        }
        
        func mapping() throws {
            if map2.count != height || map2[0].count != width {
                throw NSError(domain: "Error message", code: -1, userInfo: nil)
            }
            var elevation: Int
            var gap: Int // to fill the gap
            var maxY: Int
            var minY: Int
            //前後にスペースが入っていたら消す。
            for i in 0 ..< height {
                for j in 0 ..< width {
                    tempArray.append(map2[i][j].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                }
                map3.append(tempArray)
                tempArray = []
            }
            //数字以外の文字が入っていたときの処理
            for i in 0 ..< height {
                for j in 0 ..< width {
                    if map3[i][j] == "Infinity" {
                        tempArray2.append(10000)
                    } else if map3[i][j] == "Nan" {
                        tempArray2.append(0)
                    }else if map3[i][j] == "" {
                        tempArray2.append(0)
                    } else {
                        if map3[i][j].isOnlyNumeric() {//数字のみ
                            tempArray2.append(Int(ceil(Float(map3[i][j])! * magnification)))
                        } else {
                            let temp = map3[i][j].remove(characterSet: .decimalDigits)//数字を削除
                            if temp == "."{// 小数点を含む数字のみ
                                tempArray2.append(Int(ceil(Float(map3[i][j])! * magnification)))
                            } else if temp == "-."{// 小数点を含む数字のみ（マイナス）
                                tempArray2.append(Int(ceil(Float(map3[i][j])! * magnification)))
                            } else if temp == "-"{// 整数（マイナス）
                                tempArray2.append(Int(ceil(Float(map3[i][j])! * magnification)))
                            } else {
                                tempArray2.append(0)
                            }
                        }
                    }
                }
                map4.append(tempArray2)
                tempArray2 = []
            }
            //y の最大値、最小値
            minY = map4[0][0]
            maxY = map4[0][0]
            
            for i in 0 ..< height {
                for j in 0 ..< width {
                    if map4[i][j] == 10000 { // infinity
                        elevation = 0
                    } else if map4[i][j] > 100 {
                        elevation = 100
                    } else if map4[i][j] < -100 {
                        elevation = -100
                    } else {
                        elevation = map4[i][j]
                    }
                    if minY > map4[i][j] {
                        minY = map4[i][j]
                    }
                    if maxY < map4[i][j] {
                        maxY = map4[i][j]
                    }
                    if elevation > 0 {
                        // Calculate gaps
                        if height == 1 {
                            if j == 0 {
                                gap = map4[i][j] - [map4[i][j + 1]].min()!
                            } else if j == width - 1 {
                                gap = map4[i][j] - [map4[i][j - 1]].min()!
                            } else {
                                gap = map4[i][j] - [map4[i][j - 1], map4[i][j + 1]].min()!
                            }
                        } else if i == 0 {
                            if j == 0 {
                                if width == 1 {
                                    gap = map4[i][j] - [map4[i + 1][j]].min()!
                                } else {
                                    gap = map4[i][j] - [map4[i + 1][j], map4[i][j + 1]].min()!
                                }
                            } else if j == width - 1 {
                                gap = map4[i][j] - [map4[i + 1][j], map4[i][j - 1]].min()!
                            } else {
                                gap = map4[i][j] - [map4[i + 1][j], map4[i][j - 1], map4[i][j + 1]].min()!
                            }
                        } else if i == height - 1 {
                            if j == 0 {
                                if width == 1 {
                                    gap = map4[i][j] - [map4[i - 1][j]].min()!
                                } else {
                                    gap = map4[i][j] - [map4[i - 1][j], map4[i][j + 1]].min()!
                                }
                            } else if j == width - 1 {
                                gap = map4[i][j] - [map4[i - 1][j], map4[i][j - 1]].min()!
                            } else {
                                gap = map4[i][j] - [map4[i - 1][j], map4[i][j - 1], map4[i][j + 1]].min()!
                            }
                        } else {
                            if j == 0 {
                                if width == 1 {
                                    gap = map4[i][j] - [map4[i - 1][j], map4[i + 1][j]].min()!
                                } else {
                                    gap = map4[i][j] - [map4[i - 1][j], map4[i + 1][j], map4[i][j + 1]].min()!
                                }
                            } else if j == width - 1 {
                                gap = map4[i][j] - [map4[i - 1][j], map4[i + 1][j], map4[i][j - 1]].min()!
                            } else {
                                gap = map4[i][j] - [map4[i - 1][j], map4[i + 1][j], map4[i][j - 1], map4[i][j + 1]].min()!
                            }
                        }
                    } else {
                        // Calculate gaps
                        if height == 1 {
                            if j == 0 {
                                gap = -map4[i][j] + [map4[i][j + 1]].max()!
                            } else if j == width - 1 {
                                gap = -map4[i][j] + [map4[i][j - 1]].max()!
                            } else {
                                gap = -map4[i][j] + [map4[i][j - 1], map4[i][j + 1]].max()!
                            }
                        } else if i == 0 {
                            if j == 0 {
                                if width == 1 {
                                    gap = -map4[i][j] + [map4[i + 1][j]].max()!
                                } else {
                                    gap = -map4[i][j] + [map4[i + 1][j], map4[i][j + 1]].max()!
                                }
                            } else if j == width - 1 {
                                gap = -map4[i][j] + [map4[i + 1][j], map4[i][j - 1]].max()!
                            } else {
                                gap = -map4[i][j] + [map4[i + 1][j], map4[i][j - 1], map4[i][j + 1]].max()!
                            }
                        } else if i == height - 1 {
                            if j == 0 {
                                if width == 1 {
                                    gap = -map4[i][j] + [map4[i - 1][j]].max()!
                                } else {
                                    gap = -map4[i][j] + [map4[i - 1][j], map4[i][j + 1]].max()!
                                }
                            } else if j == width - 1 {
                                gap = -map4[i][j] + [map4[i - 1][j], map4[i][j - 1]].max()!
                            } else {
                                gap = -map4[i][j] + [map4[i - 1][j], map4[i][j - 1], map4[i][j + 1]].max()!
                            }
                        } else {
                            if j == 0 {
                                if width == 1 {
                                    gap = -map4[i][j] + [map4[i - 1][j], map4[i + 1][j]].max()!
                                } else {
                                    gap = -map4[i][j] + [map4[i - 1][j], map4[i + 1][j], map4[i][j + 1]].max()!
                                }
                            } else if j == width - 1 {
                                gap = -map4[i][j] + [map4[i - 1][j], map4[i + 1][j], map4[i][j - 1]].max()!
                            } else {
                                gap = -map4[i][j] + [map4[i - 1][j], map4[i + 1][j], map4[i][j - 1], map4[i][j + 1]].max()!
                            }
                        }
                        
                    }
                    drawMap(i: i, j: j, elevation: elevation, gap: gap, minY: minY, maxY: maxY, upward: upward)
                }
            }
        }
        
        if map_data.contains("csv") || map_data.contains("txt") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_csv_file = dir.appendingPathComponent( map_data )
                do {
                    let csv = try String( contentsOf: path_csv_file, encoding: String.Encoding.utf8 )
                    maps = csv.components(separatedBy: "\r\n")
                    if maps.count == 1 {
                        maps = csv.components(separatedBy: "\n")
                    }
                    if maps.count == 1 {
                        maps = csv.components(separatedBy: "\r")
                    }
                    if maps.count == 1 { // from Web地理院地図（http://maps.gsi.go.jp）
                        _maps = maps[0].components(separatedBy: ",")
                        for i in 0 ..< height {
                            for j in 0 ..< width {
                                tempArray.append(_maps[i * width + j])
                            }
                            map2.append(tempArray)
                            tempArray = []
                        }
                        try mapping()
                    } else if maps.count >= height { // from Web地形自動生成（http://www.bekkoame.ne.jp/ro/kami/LandMaker/LandMaker.html） or self made map
                        if maps[0].contains("map") || maps[0].contains("Map") {
                            maps.removeFirst()
                        }
                        for i in 0 ..< height {
                            if maps[i].contains(",") {
                                map2.append(maps[i].components(separatedBy: ","))
                            } else if maps[i].contains("\t") {
                                map2.append(maps[i].components(separatedBy: "\t"))
                            } else {
                                // replace all
                                while true {
                                    if let range = maps[i].range(of: "  ") {
                                        maps[i].replaceSubrange(range, with: " ")
                                    } else {
                                        break
                                    }
                                }
                                map2.append(maps[i].components(separatedBy: " "))
                            }
                        }
                        try mapping()
                    } else {
                        Enable_show_message = true
                        //error message
                        self.showMessage(text: "Format Error".localized)
                    }
                } catch {
                    Enable_show_message = true
                    //error message
                    self.showMessage(text: "No such file".localized)
                }
            }
        } else {
            //Read from Scratch
            var _map_data = map_data
            // replace all for Web地形自動生成
            while true {
                if let range = _map_data.range(of: "  ") {
                    _map_data.replaceSubrange(range, with: " ")
                } else {
                    break
                }
            }
            while true {
                if let range = _map_data.range(of: "\t ") {
                    _map_data.replaceSubrange(range, with: "\t")
                } else {
                    break
                }
            }
            maps = _map_data.components(separatedBy: " ")
            if maps[0].contains("map") || maps[0].contains("Map") {
                maps.removeFirst()
            }
            if maps.count >= width * height {// separated by " "
                for i in 0 ..< height {
                    for j in 0 ..< width {
                        tempArray.append(maps[i * width + j])
                    }
                    map2.append(tempArray)
                    tempArray = []
                }
                do {
                    try mapping()
                } catch {
                    //error message
                    self.showMessage(text: "Format Error".localized)
                }
            } else if maps.count >= height {// separated by "," or "\t"
                for i in 0 ..< height {
                    if maps[i].contains(",") {
                        map2.append(maps[i].components(separatedBy: ","))
                    } else if maps[i].contains("\t") {
                        map2.append(maps[i].components(separatedBy: "\t"))
                    }
                }
                do {
                    try mapping()
                } catch {
                    Enable_show_message = true
                    //error message
                    self.showMessage(text: "Format Error".localized)
                }
            } else {
                Enable_show_message = true
                //error message
                self.showMessage(text: "Format Error".localized)
            }
        }
        Enable_show_message = true
    }
    
    func pin(pin_data: String, width: Int, height: Int, magnification: Float, up_left_latitude: Float, up_left_longitude: Float, down_right_latitude: Float, down_right_longitude: Float, step: Int) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        self.showMessage(text: "Setting pins...".localized)
        
        Enable_show_message = false// 色指定など余計なメッセージを表示させない
        
        var pins2: [[String]] = [[String]]()
        var pins3: [[String]] = [[String]]()
        var pins4: [[Float]] = [[Float]]()
        var pins: [String] = []
        var tempArray: [String] = []
        var tempArray2: [Float] = []
        
        func standPins(i: Int, j: Int, elevation: Int, magnification: Float, step: Int) {
            let _x1: Float = Float(height) / 2.0 - Float(j)
            let _y1: Float = 0.0
            let _z1: Float = Float(i + step) - Float(width) / 2.0
            let _x2: Float = Float(height) / 2.0 - Float(j)
            let _y2: Float = Float(elevation) * magnification
            let _z2: Float = Float(i + step) - Float(width) / 2.0
            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
        }
        
        func pinning() throws {
            if pins2.count < 2 || pins2[0].count < 3 || Int(pins2[0][0]) == nil  {
                throw NSError(domain: "Error message", code: -1, userInfo: nil)
            }
            //前後にスペースが入っていたら消す。
            for i in 0 ..< pins2.count {
                if pins2[i][0] != ""{
                    for j in 0 ..< 3 {
                        tempArray.append(pins2[i][j].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
                    }
                    pins3.append(tempArray)
                    tempArray = []            }
            }
            //数字以外の文字が入っていたときの処理
            for i in 0 ..< pins3.count {
                for j in 0 ..< 3 {
                    if let num: Float = Float(pins3[i][j]) {
                        tempArray2.append(num)
                    } else {
                        tempArray2.append(0.0)
                    }
                }
                pins4.append(tempArray2)
                tempArray2 = []
            }
            
            self.setColor(r: Int(pins4[0][0]), g: Int(pins4[0][1]), b: Int(pins4[0][2]))
            for k in 1 ..< pins4.count {
                let i = Int(Float(width) * (pins4[k][1] - up_left_longitude) / (down_right_longitude - up_left_longitude))
                let j = height - Int(Float(height) * (pins4[k][0] - down_right_latitude) / (up_left_latitude - down_right_latitude))
                let elevation = Int(pins4[k][2])
                standPins(i: i, j: j, elevation: elevation, magnification: magnification, step: step)
            }
        }
        
        if pin_data.contains("csv") || pin_data.contains("txt") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_csv_file = dir.appendingPathComponent( pin_data )
                do {
                    let csv = try String( contentsOf: path_csv_file, encoding: String.Encoding.utf8 )
                    pins = csv.components(separatedBy: "\r\n")
                    if pins.count == 1 {
                        pins = csv.components(separatedBy: "\n")
                    }
                    if pins.count == 1 {
                        pins = csv.components(separatedBy: "\r")
                    }
                    if pins.count >= 3 && (pins[0].contains("pin") || pins[0].contains("Pin")) {
                        pins.removeFirst()
                        for i in 0 ..< pins.count {
                            if pins[i].contains(",") {
                                pins2.append(pins[i].components(separatedBy: ","))
                            } else if pins[i].contains("\t") {
                                pins2.append(pins[i].components(separatedBy: "\t"))
                            } else {
                                pins2.append(pins[i].components(separatedBy: " "))
                            }
                        }
                        do {
                            try pinning()
                        } catch {
                            Enable_show_message = true
                            //error message
                            showMessage(text: "Format Error".localized)
                        }
                    } else {
                        Enable_show_message = true
                        //error message
                        showMessage(text: "Format Error".localized)
                    }
                } catch {
                    Enable_show_message = true
                    //error message
                    showMessage(text: "No such file".localized)
                }
            }
        } else {
            //Read from Scratch
            pins = pin_data.components(separatedBy: " ")
            if pins.count >= 3 && (pins[0].contains("pin") || pins[0].contains("Pin")) {
                pins.removeFirst()
                if pins[0].contains(",") || pins[0].contains("\t") {
                    for i in 0 ..< pins.count {
                        if pins[i].contains(",") {
                            pins2.append(pins[i].components(separatedBy: ","))
                        } else {
                            pins2.append(pins[i].components(separatedBy: "\t"))
                        }
                    }
                } else {// separated by " "
                    if pins.count % 3 == 0 {
                        for i in 0 ..< pins.count / 3 {
                            for j in 0 ..< 3 {
                                tempArray.append(pins[3 * i + j])
                            }
                            pins2.append(tempArray)
                            tempArray = []
                        }
                    } else {
                        Enable_show_message = true
                        //error message
                        self.showMessage(text: "Format Error".localized)
                    }
                }
                do {
                    try pinning()
                } catch {
                    Enable_show_message = true
                    //error message
                    self.showMessage(text: "Format Error".localized)
                }
            } else {
                Enable_show_message = true
                //error message
                self.showMessage(text: "Format Error".localized)
            }
        }
        Enable_show_message = true
    }
    
    func molecular_structure(x: Float, y: Float, z: Float, magnification: Float, mld_file: String) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        //message
        self.showMessage(text: "Molecular Structure".localized)
        
        Enable_show_message = false// 色指定など余計なメッセージを表示させない
        
        var position = [[String]]()
        var line = [[String]]()
        var mlds: [String] = []
        
        func createStructure() throws {
            if mlds.count < 5 || Int(mlds[1]) == nil {
                throw NSError(domain: "Error message", code: -1, userInfo: nil)
            }
            var _x: Float
            var _y: Float
            var _z: Float
            var _r: Float
            var _x1: Float
            var _y1: Float
            var _z1: Float
            var _x2: Float
            var _y2: Float
            var _z2: Float
            
            let loop1: Int = Int(mlds[1])!
            for i in 0 ..< loop1 {
                position.append(mlds[2 + i].components(separatedBy: ","))
            }
            let loop2: Int = Int(mlds[2 + loop1])!
            for i in 0 ..< loop2 {
                line.append(mlds[3 + loop1 + i].components(separatedBy: ","))
            }
            for i in 0 ..< loop1 {
                switch (position[i][3]) {
                case "1": //Hydrogen 水素
                    self.setColor(r: 255, g: 255, b: 255)
                case "5": //Boron ホウ素
                    self.setColor(r: 245, g: 245, b: 220)
                case "6": //Carbon 炭素
                    self.setColor(r: 0, g: 0, b: 0)
                case "7": //Nitrogen 窒素
                    self.setColor(r: 0, g: 0, b: 255)
                case "8": //Oxygen 酸素
                    self.setColor(r: 255, g: 0, b: 0)
                case "15": //Phosphorus リン
                    self.setColor(r: 255, g: 0, b: 255)
                case "16": //Sulfur 硫黄
                    self.setColor(r: 255, g: 255, b: 0)
                case "9": //Fluorine フッ素 ハロゲン
                    self.setColor(r: 0, g: 255, b: 255)
                case "17": //Chlorine 塩素 ハロゲン
                    self.setColor(r: 0, g: 255, b: 255)
                case "35": //Bromine 臭素 ハロゲン
                    self.setColor(r: 0, g: 255, b: 255)
                case "53": //Iodine ヨウ素 ハロゲン
                    self.setColor(r: 0, g: 255, b: 255)
                case "85": //Astatine アスタチン ハロゲン
                    self.setColor(r: 0, g: 255, b: 255)
                case "11": //Sodium ナトリウム
                    self.setColor(r: 192, g: 192, b: 192)
                case "12": //Magnesium マグネシウム
                    self.setColor(r: 192, g: 192, b: 192)
                case "13": //Alminium アルミニウム
                    self.setColor(r: 192, g: 192, b: 192)
                case "14": //Silicon ケイ素
                    self.setColor(r: 192, g: 192, b: 192)
                case "19": //Potassium カリウム
                    self.setColor(r: 192, g: 192, b: 192)
                case "20": //Calcium カルシウム
                    self.setColor(r: 192, g: 192, b: 192)
                case "24": //Chromium クロム
                    self.setColor(r: 192, g: 192, b: 192)
                case "25": //Manganese マンガン
                    self.setColor(r: 192, g: 192, b: 192)
                case "26": //Iron 鉄
                    self.setColor(r: 192, g: 192, b: 192)
                case "27": //Cobalt コバルト
                    self.setColor(r: 192, g: 192, b: 192)
                case "28": //Nickel ニッケル
                    self.setColor(r: 192, g: 192, b: 192)
                case "29": //Copper 銅
                    self.setColor(r: 192, g: 192, b: 192)
                case "30": //Zinc 亜鉛
                    self.setColor(r: 192, g: 192, b: 192)
                case "47": //Silver 銀
                    self.setColor(r: 192, g: 192, b: 192)
                case "48": //Cadmium カドミウム
                    self.setColor(r: 192, g: 192, b: 192)
                case "79": //Gold 金
                    self.setColor(r: 192, g: 192, b: 192)
                default:
                    self.setColor(r: 192, g: 192, b: 192)
                    break
                }
                _x = x + Float(position[i][0])! * magnification
                _y = y + Float(position[i][1])! * magnification
                _z = z + Float(position[i][2])! * magnification
                _r = round(magnification) / 2.0
                _r = _r < 3.0 ? 3.0 : _r
                self.setSphere(x: _x, y: _y, z: _z, r: _r)
            }
            
            for j in 0 ..< loop2 {
                _x1 = x + Float(position[Int(line[j][0])! - 1][0])! * magnification
                _y1 = y + Float(position[Int(line[j][0])! - 1][1])! * magnification
                _z1 = z + Float(position[Int(line[j][0])! - 1][2])! * magnification
                _x2 = x + Float(position[Int(line[j][1])! - 1][0])! * magnification
                _y2 = y + Float(position[Int(line[j][1])! - 1][1])! * magnification
                _z2 = z + Float(position[Int(line[j][1])! - 1][2])! * magnification
                let vector2 = [abs(_x2 - _x1), abs(_y2 - _y1), abs(_z2 - _z1)]
                
                let index:Int? = vector2.index(of: vector2.max()!)
                
                switch (index) {
                case 0:
                    if line[j].count >= 3 {
                        switch line[j][2] {
                        case "1"://単結合
                            self.setColor(r: 127, g: 127, b: 127)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                        case "2"://二重結合
                            self.setColor(r: 255, g: 0, b: 0)
                            self.setLine(x1: _x1, y1: _y1 + 1.5, z1: _z1, x2: _x2, y2: _y2 + 1.5, z2: _z2)
                            self.setLine(x1: _x1, y1: _y1 - 1.5, z1: _z1, x2: _x2, y2: _y2 - 1.5, z2: _z2)
                        case "3"://三重結合
                            self.setColor(r: 0, g: 255, b: 0)
                            self.setLine(x1: _x1, y1: _y1 + 1.5, z1: _z1, x2: _x2, y2: _y2 + 1.5, z2: _z2)
                            self.setLine(x1: _x1, y1: _y1 - 1.0, z1: _z1 + 1.0, x2: _x2, y2: _y2 - 1.0, z2: _z2 + 1.0)
                            self.setLine(x1: _x1, y1: _y1 - 01.0, z1: _z1 - 1.0, x2: _x2, y2: _y2 - 1.0, z2: _z2 - 1.0)
                        default:
                            self.setColor(r: 0, g: 0, b: 0)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                        }
                    } else {
                        self.setColor(r: 0, g: 0, b: 0)
                        self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                    }
                case 1:
                    if line[j].count >= 3 {
                        switch line[j][2] {
                        case "1"://単結合
                            self.setColor(r: 127, g: 127, b: 127)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                        case "2"://二重結合
                            self.setColor(r: 255, g: 0, b: 0)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1 + 1.5, x2: _x2, y2: _y2, z2: _z2 + 1.5)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1 - 1.5, x2: _x2, y2: _y2, z2: _z2 - 1.5)
                        case "3"://三重結合
                            self.setColor(r: 0, g: 255, b: 0)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1 + 1.5, x2: _x2, y2: _y2, z2: _z2 + 1.5)
                            self.setLine(x1: _x1 + 1.0, y1: _y1, z1: _z1 - 1.0, x2: _x2 + 1.0, y2: _y2, z2: _z2 - 1.0)
                            self.setLine(x1: _x1 - 1.0, y1: _y1, z1: _z1 - 1.0, x2: _x2 - 1.0, y2: _y2, z2: _z2 - 1.0)
                        default:
                            self.setColor(r: 0, g: 0, b: 0)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                        }
                    } else {
                        self.setColor(r: 0, g: 0, b: 0)
                        self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                    }
                case 2:
                    if line[j].count >= 3 {
                        switch line[j][2] {
                        case "1"://単結合
                            self.setColor(r: 127, g: 127, b: 127)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                        case "2"://二重結合
                            self.setColor(r: 255, g: 0, b: 0)
                            self.setLine(x1: _x1 + 1.5, y1: _y1, z1: _z1, x2: _x2 + 1.5, y2: _y2, z2: _z2)
                            self.setLine(x1: _x1 - 1.5, y1: _y1, z1: _z1, x2: _x2 - 1.5, y2: _y2, z2: _z2)
                        case "3"://三重結合
                            self.setColor(r: 0, g: 255, b: 0)
                            self.setLine(x1: _x1 + 1.5, y1: _y1, z1: _z1, x2: _x2 + 1.5, y2: _y2, z2: _z2)
                            self.setLine(x1: _x1 - 1.0, y1: _y1 + 1.0, z1: _z1, x2: _x2 - 1.0, y2: _y2 + 1.0, z2: _z2)
                            self.setLine(x1: _x1 - 1.0, y1: _y1 - 1.0, z1: _z1, x2: _x2 - 1.0, y2: _y2 - 1.0, z2: _z2)
                        default:
                            self.setColor(r: 0, g: 0, b: 0)
                            self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                        }
                    } else {
                        self.setColor(r: 0, g: 0, b: 0)
                        self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
                    }
                default:
                    Enable_show_message = true
                    showMessage(text: "Incorrect format".localized)
                    break
                }
            }
        }
        
        if mld_file.contains("mld") || mld_file.contains("csv") || mld_file.contains("txt") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_mld_file = dir.appendingPathComponent( mld_file )
                do {
                    let mld = try String( contentsOf: path_mld_file, encoding: String.Encoding.utf8 )
                    mlds = mld.components(separatedBy: "\r\n")
                    if mlds.count == 1 {
                        mlds = mld.components(separatedBy: "\n")
                    }
                    if mlds.count == 1 {
                        mlds = mld.components(separatedBy: "\r")
                    }
                    do {
                        try createStructure()
                    } catch {
                        Enable_show_message = true
                        self.showMessage(text: "Format Error".localized)
                    }
                } catch {
                    Enable_show_message = true
                    //error message
                    self.showMessage(text: "No such file".localized)
                }
            }
        } else {
            //Read from Scratch
            mlds = mld_file.components(separatedBy: " ")
            do {
                try createStructure()
            } catch {
                Enable_show_message = true
                //error message
                self.showMessage(text: "Format Error".localized)
            }
        }
        Enable_show_message = true
    }
    
    func setColor(r: Int, g: Int, b: Int) {
        red = r < 0 ? -r%256 : r%256
        green = g < 0 ? -g%256 : g%256
        blue = b < 0 ? -b%256 : b%256
        
        //message
        self.showMessage(text: "RGB: (\(red):\(green):\(blue))")
    }
    
    func setAlpha(a: Float) {
        var _a: Float = a < 0 ? -a : a
        while(_a > 1) {
            _a /= 10.0
        }
        alpha = _a
        
        //message
        self.showMessage(text: "alpha: (\(_a))")
    }
    
    func changeLayer(l: String) {
        if l == "1" || l == "2" || l == "3" {
            layerChanged = true
            layer = l
            //message
            self.showMessage(text: "Change layer: ".localized + String(l))
        } else {
            //error message
            self.showMessage(text: "Only 1 or 2 or 3".localized)
        }
    }
    
    func changeShape(shape: String) {
        if shape == "cube" || shape == "sphere" || shape == "cylinder" || shape == "cone" || shape == "pyramid" {
            basicShape = shape
            //message
            self.showMessage(text: "Change basic shape: ".localized + shape)
        } else {
            //error message
            self.showMessage(text: "Undefined shape".localized)
        }
    }
    
    func removeCube(x: Float, y: Float, z: Float) {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        //小数点以下を .0 または .5 に変換
        let _x: Float = round(2.0 * x) / 2.0
        let _y: Float = round(2.0 * y) / 2.0
        let _z: Float = round(2.0 * z) / 2.0
        
        let cubeNode = cubeNodes[String(_x) + "_" + String(_y) + "_" + String(_z)]
        let cubeNode2 = cubeNodes2[String(_x) + "_" + String(_y) + "_" + String(_z)]
        let cubeNode3 = cubeNodes3[String(_x) + "_" + String(_y) + "_" + String(_z)]
        if (cubeNode == nil && cubeNode2 == nil && cubeNode3 == nil) {
            //error message
            self.showMessage(text: "No block".localized)
        } else {
            if (cubeNode != nil) {
                //message
                self.showMessage(text: "Remove a block".localized)
                cubeNode?.removeFromParentNode()
            }
            if (cubeNode2 != nil) {
                //message
                self.showMessage(text: "Remove a block from layer2".localized)
                cubeNode2?.removeFromParentNode()
            }
            if (cubeNode3 != nil) {
                //message
                self.showMessage(text: "Remove a block from layer3".localized)
                cubeNode3?.removeFromParentNode()
            }
        }
    }
    
    func reset() {
        if (originPosition == nil) {
            //error message
            self.showMessage(text: "Set origin".localized)
            return
        }
        // remove the light you added yourself
        if lightChanged {
            for (id, lightNode) in lightNodes {
                lightNode.removeFromParentNode()
            }
            lightNodes = [:]
        }
        
        switch layer {
        case "1":
            self.showMessage(text: "Reset".localized)
            for (id, cubeNode) in cubeNodes {
                cubeNode.removeFromParentNode()
            }
            cubeNodes = [:]
        case "2":
            self.showMessage(text: "Reset layer2".localized)
            for (id, cubeNode) in cubeNodes2 {
                cubeNode.removeFromParentNode()
            }
            cubeNodes2 = [:]
        case "3":
            self.showMessage(text: "Reset layer3".localized)
            for (id, cubeNode) in cubeNodes3 {
                cubeNode.removeFromParentNode()
            }
            cubeNodes3 = [:]
        default:
            self.showMessage(text: "No layer".localized)
            break
        }
    }
    
    @IBAction func togglePlanesButtonTapped(_ sender: UIButton) {
        if (self.settingOrigin) {
            self.settingOrigin = false
            self.xAxisNode?.isHidden = true
            self.yAxisNode?.isHidden = true
            self.zAxisNode?.isHidden = true
            
            togglePlanesButton.setTitle("Show".localized, for: .normal)
            helpButton.isHidden = true
            roomIDLabel.isHidden = true
            sendMapButton.isHidden = true
            mappingStatusLabel.isHidden = true
            sessionInfoView.isHidden = true
            restartButton.isHidden = true
            multipeerButton.isHidden = true
            
            for (identifier, planeNode) in planeNodes {
                planeNode.isHidden = true
            }
        } else {
            self.settingOrigin = true
            
            self.xAxisNode?.isHidden = false
            self.yAxisNode?.isHidden = false
            self.zAxisNode?.isHidden = false
            
            togglePlanesButton.setTitle("Hide".localized, for: .normal)
            helpButton.isHidden = false
            roomIDLabel.isHidden = false
            sessionInfoView.isHidden = false
            restartButton.isHidden = false
            multipeerButton.isHidden = false
            if multipeerState {
                sendMapButton.isHidden = false
                mappingStatusLabel.isHidden = false
            }
            
            for (identifier, planeNode) in planeNodes {
                planeNode.isHidden = false
            }
        }
    }
    
    @IBAction func helpButtonTapped(_ sender: UIButton) {
        guard let url = URL(string: "https://github.com/champierre/s2ar/blob/master/README.md") else { return }
        UIApplication.shared.open(url)
    }
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //multiuser
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        // Strat multipeer session after tapping multipeerButton
        multipeerSession.stopSession()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
        //sceneView.debugOptions = .showWireframe
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        // WebSocket
        let socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            self.roomId = String(format: "%04d", Int(arc4random_uniform(10000))) + "-" + String(format: "%04d", Int(arc4random_uniform(10000)))
            self.roomIDLabel.isHidden = false
            self.roomIDLabel.text = " ID: " + self.roomId + " "
            self.connectionState = false
            var jsonDic = Dictionary<String, Any>()
            jsonDic["roomId"] = self.roomId
            jsonDic["command"] = "join"
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDic)
                let jsonStr = String(bytes: jsonData, encoding: .utf8)!
                socket.emit("from_client", jsonStr)
            } catch (let e) {
                print(e)
            }
        }
        
        socket.on("from_server") { data, ack in
            if self.connectionState == false {
                self.roomIDLabel.isHidden = false
                self.showMessage(text: "Connected".localized)
                self.connectionState = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    // 3.0秒後に実行したい処理
                    self.roomIDLabel.isHidden = true
                }
            }
            if let msg = data[0] as? String {
                print(msg)
                let units = msg.components(separatedBy: ":")
                let action = units[0]
                switch action {
                case "change_cube_size":
                    let magnification = Float(units[1])
                    self.changeCubeSize(magnification: magnification!)
                case "set_cube":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    if x == nil || y == nil || z == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setCube(x: x!, y: y!, z: z!)
                    }
                case "set_box":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let w = Float(units[4])
                    let d = Float(units[5])
                    let h = Float(units[6])
                    if x == nil || y == nil || z == nil || w == nil || d == nil || h == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setBox(x: x!, y: y!, z: z!, w: w!, d: d!, h: h!)
                    }
                case "set_cylinder":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let r = Float(units[4])
                    let h = Float(units[5])
                    let a = units[6]
                    if x == nil || y == nil || z == nil || r == nil || h == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setCylinder(x: x!, y: y!, z: z!, r: r!, h: h!, a: a)
                    }
                case "set_hexagon":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let r = Float(units[4])
                    let h = Float(units[5])
                    let a = units[6]
                    if x == nil || y == nil || z == nil || r == nil || h == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setHexagon(x: x!, y: y!, z: z!, r: r!, h: h!, a: a)
                    }
                case "set_sphere":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let r = Float(units[4])
                    if x == nil || y == nil || z == nil || r == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setSphere(x: x!, y: y!, z: z!, r: r!)
                    }
                case "set_char":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let c = units[4]
                    let a = units[5]
                    if x == nil || y == nil || z == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setChar(x: x!, y: y!, z: z!, c: c, a: a)
                    }
                case "set_line":
                    let x1 = Float(units[1])
                    let y1 = Float(units[2])
                    let z1 = Float(units[3])
                    let x2 = Float(units[4])
                    let y2 = Float(units[5])
                    let z2 = Float(units[6])
                    if x1 == nil || y1 == nil || z1 == nil || x2 == nil || y2 == nil || z2 == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setLine(x1: x1!, y1: y1!, z1: z1!, x2: x2!, y2: y2!, z2: z2!)
                    }
                case "set_roof":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let w = Float(units[4])
                    let d = Float(units[5])
                    let h = Float(units[6])
                    let a = units[7]
                    if x == nil || y == nil || z == nil || w == nil || d == nil || h == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setRoof(x: x!, y: y!, z: z!, w: Int(w!), d: d!, h: Int(h!), a: a)
                    }
                case "polygon_file_format":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let ply_file = units[4]
                    if x == nil || y == nil || z == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.polygonFileFormat(x: x!, y: y!, z: z!, ply_file: ply_file)
                    }
                case "animation":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let differenceX = Float(units[4])
                    let differenceY = Float(units[5])
                    let differenceZ = Float(units[6])
                    let time = Double(units[7])
                    let times = Float(units[8])
                    let files = units[9]
                    if x == nil || y == nil || z == nil || differenceX == nil || differenceY == nil || differenceZ == nil || time == nil || times == nil || time! <= 0 || times! <= 0 {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.animation(x: x!, y: y!, z: z!, differenceX: differenceX!, differenceY: differenceY!, differenceZ: differenceZ!, time: time!, times: Int(times!), files: files)
                    }
                case "map":
                    let map_data = units[1]
                    let width = Float(units[2])
                    let height = Float(units[3])
                    let magnification = Float(units[4])
                    let r1 = Float(units[5])
                    let g1 = Float(units[6])
                    let b1 = Float(units[7])
                    let r2 = Float(units[8])
                    let g2 = Float(units[9])
                    let b2 = Float(units[10])
                    let upward = Float(units[11])
                    if width == nil || height == nil || magnification == nil || r1 == nil || g1 == nil || b1 == nil || r2 == nil || g2 == nil || b2 == nil || upward == nil || width! < 1 || height! < 1 || magnification! <= 0.0 {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.map(map_data: map_data, width: Int(width!), height: Int(height!), magnification: magnification!, r1: Int(r1!), g1: Int(g1!), b1: Int(b1!), r2: Int(r2!), g2: Int(g2!), b2: Int(b2!), upward: Int(upward!))
                    }
                case "pin":
                    let pin_data = units[1]
                    let width = Float(units[2])
                    let height = Float(units[3])
                    let magnification = Float(units[4])
                    let up_left_latitude = Float(units[5])
                    let up_left_longitude = Float(units[6])
                    let down_right_latitude = Float(units[7])
                    let down_right_longitude = Float(units[8])
                    let step = Float(units[9])
                    if width == nil || height == nil || magnification == nil || up_left_latitude == nil || up_left_longitude == nil || down_right_latitude == nil || down_right_longitude == nil || step == nil || width! < 1 || height! < 1 {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.pin(pin_data: pin_data, width: Int(width!), height: Int(height!), magnification: magnification!, up_left_latitude: up_left_latitude!, up_left_longitude: up_left_longitude!, down_right_latitude: down_right_latitude!, down_right_longitude: down_right_longitude!, step: Int(step!))
                    }
                case "molecular_structure":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let magnification = Float(units[4])
                    let mld_file = units[5]
                    if x == nil || y == nil || z == nil || magnification == nil || magnification! <= 0.0 {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.molecular_structure(x: x!, y: y!, z: z!, magnification: magnification!, mld_file: mld_file)
                    }
                case "set_color":
                    let r = Float(units[1])
                    let g = Float(units[2])
                    let b = Float(units[3])
                    if r == nil || g == nil || b == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setColor(r: Int(r!), g: Int(g!), b: Int(b!))
                    }
                case "set_alpha":
                    let a = Float(units[1])
                    if a == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.setAlpha(a: Float(a!))
                    }
                case "change_layer":
                    let layer: String? = units[1]// 1 or 2 or 3
                    if layer == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.changeLayer(l: layer!)
                    }
                case "change_shape":
                    let shape: String? = units[1]// cube or spehre or cylinder or cone or pyramid
                    if shape == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.changeShape(shape: shape!)
                    }
                case "change_light":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    let intensity = Float(units[4])
                    if x == nil || y == nil || z == nil || intensity == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.changeLight(x: x!, y: y!, z: z!, intensity: intensity!)
                    }
                case "remove_cube":
                    let x = Float(units[1])
                    let y = Float(units[2])
                    let z = Float(units[3])
                    if x == nil || y == nil || z == nil {
                        //error message
                        self.showMessage(text: "Invalid value".localized)
                    } else {
                        self.removeCube(x: x!, y: y!, z: z!)
                    }
                case "reset":
                    self.reset()
                default:
                    print("default")
                }
            }
        }
        
        socket.connect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionInfoLabel.text = "Session failed: ".localized + error.localizedDescription
        resetTracking(nil)
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        sessionInfoLabel.text = "Session was interrupted".localized
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        sessionInfoLabel.text = "Session interruption ended".localized
    }
    
    @IBAction func handleTapFrom(_ sender: UITapGestureRecognizer) {
        
        if !settingOrigin {
            return
        }
        let results = sceneView.hitTest(sender.location(in: sceneView),
                                        types: [.existingPlaneUsingGeometry])
        
        guard let hitResult = results.first else { return }
        world_origin = hitResult.worldTransform
        //y軸回転を合わせる
        world_origin.columns.0.x = 1.0
        world_origin.columns.0.z = 0.0
        world_origin.columns.2.x = 0.0
        world_origin.columns.2.z = 1.0
        
        if originPosition != nil {
            originPosition = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                            hitResult.worldTransform.columns.3.y,
                                            hitResult.worldTransform.columns.3.z)
            let xAxisPosition =  SCNVector3Make(hitResult.worldTransform.columns.3.x + 0.05,
                                                hitResult.worldTransform.columns.3.y,
                                                hitResult.worldTransform.columns.3.z)
            let yAxisPosition =  SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                                hitResult.worldTransform.columns.3.y + 0.05,
                                                hitResult.worldTransform.columns.3.z)
            let zAxisPosition =  SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                                hitResult.worldTransform.columns.3.y,
                                                hitResult.worldTransform.columns.3.z + 0.05)
            
            xAxisNode.position = xAxisPosition
            yAxisNode.position = yAxisPosition
            zAxisNode.position = zAxisPosition
            
            if !lightChanged {
                lightNode.position = SCNVector3Make(originPosition.x + CUBE_SIZE * 100,
                                                    originPosition.y + CUBE_SIZE * 100,
                                                    originPosition.z + CUBE_SIZE * 100)
                
                backLightNode.position = SCNVector3Make(originPosition.x - CUBE_SIZE * 100,
                                                        originPosition.y + CUBE_SIZE * 100,
                                                        originPosition.z + CUBE_SIZE * 100)
            }
        } else {
            originPosition = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                            hitResult.worldTransform.columns.3.y,
                                            hitResult.worldTransform.columns.3.z)
            let xAxisPosition =  SCNVector3Make(hitResult.worldTransform.columns.3.x + 0.05,
                                                hitResult.worldTransform.columns.3.y,
                                                hitResult.worldTransform.columns.3.z)
            let yAxisPosition =  SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                                hitResult.worldTransform.columns.3.y + 0.05,
                                                hitResult.worldTransform.columns.3.z)
            let zAxisPosition =  SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                                hitResult.worldTransform.columns.3.y,
                                                hitResult.worldTransform.columns.3.z + 0.05)
            // アンカーを追加する
            xAxisNode = ConeNodeX()
            xAxisNode.position = xAxisPosition
            sceneView.scene.rootNode.addChildNode(xAxisNode)
            yAxisNode = ConeNodeY()
            yAxisNode.position = yAxisPosition
            sceneView.scene.rootNode.addChildNode(yAxisNode)
            zAxisNode = ConeNodeZ()
            zAxisNode.position = zAxisPosition
            sceneView.scene.rootNode.addChildNode(zAxisNode)
            
            lightNode = LightNode(intensity: 1000)
            lightNode.position = SCNVector3Make(originPosition.x + CUBE_SIZE * 100,
                                                originPosition.y + CUBE_SIZE * 100,
                                                originPosition.z + CUBE_SIZE * 100)
            sceneView.scene.rootNode.addChildNode(lightNode)
            
            
            
            backLightNode = LightNode(intensity: 1000)
            backLightNode.position = SCNVector3Make(originPosition.x - CUBE_SIZE * 100,
                                                    originPosition.y + CUBE_SIZE * 100,
                                                    originPosition.z + CUBE_SIZE * 100)
            sceneView.scene.rootNode.addChildNode(backLightNode)
        }
        
        //multiuser  データを受信時に、Origin が置かれていなかった時の処理
        if receive_mode {
            showMessage(text: "Reproducing data...".localized)
            reproduce_cubes()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // set plane
        if let planeAnchor = anchor as? ARPlaneAnchor {
            node.addChildNode(PlaneNode(anchor: planeAnchor))
            return
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //update plane
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return  }
        guard let planeNode = node.childNodes.first as? PlaneNode else { return  }
        planeNode.update(anchor: planeAnchor)
        
        planeNodes[anchor.identifier] = planeNode
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        togglePlanesButton.setTitle("Hide".localized, for: .normal)
        helpButton.setTitle("Help".localized, for: .normal)
        multipeerButton.setTitle("Multipeer".localized, for: .normal)
        sendMapButton.setTitle("Send Virtual Objects".localized, for: .normal)
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            sendMapButton.isEnabled = false
        case .extending:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            sendMapButton.isEnabled = !multipeerSession.connectedPeers.isEmpty
        }
        mappingStatusLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    /// - Tag: GetWorldMap
    @IBAction func shareSession(_ button: UIButton) {
        /* ARAnchor を置いた worldmap を送信する方法は setColor がうまく機能しないので断念する
         sceneView.session.getCurrentWorldMap { worldMap, error in
         guard let map = worldMap
         else { print("Error: \(error!.localizedDescription)"); return }
         guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
         else { fatalError("can't encode map".localized) }
         self.multipeerSession.sendToAllPeers(data)
         }*/
        if data_all_cubes != [] {
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: data_all_cubes, requiringSecureCoding: true)
                else { fatalError("can't encode virtual objects".localized) }
            self.multipeerSession.sendToAllPeers(data)
        } else {
            showMessage(text: "No cube data".localized)
        }
    }
    
    var mapProvider: MCPeerID?
    
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        let alertController:UIAlertController = UIAlertController(title:"alert".localized, message: "Allow to receive data for multiuser session".localized, preferredStyle: .alert)
        
        // Default のaction
        let defaultAction:UIAlertAction = UIAlertAction(title: "OK".localized, style: .default, handler:{(action:UIAlertAction!) -> Void in
            // 処理
            
            self.receive_mode = true
            do {
                if let received_data = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: data) {
                    // Run the session with the received data_all_cubes
                    self.cubes = received_data as! [String]
                    self.sender_id = peer
                    if (self.originPosition == nil) {
                        //error message
                        self.receivingStatusMessage(text: "Set origin to reproduce cubes from received data".localized)
                    } else {
                        self.reproduce_cubes()
                    }
                }
                else {
                    self.receivingStatusMessage(text: "unknown data recieved from ".localized + "\(peer)")
                }
            } catch {
                self.receivingStatusMessage(text: "can't decode data recieved from ".localized + "\(peer)")
            }
        })
        
        /*
         // Destructive のaction
         let destructiveAction:UIAlertAction = UIAlertAction(title: "Destructive".localized, style: .destructive, handler:{(action:UIAlertAction!) -> Void in
         // 処理
         })
         */
        
        // Cancel のaction
        let cancelAction:UIAlertAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler:{(action:UIAlertAction!) -> Void in
            // 処理
        })
        
        // actionを追加
        alertController.addAction(cancelAction)
        alertController.addAction(defaultAction)
        //alertController.addAction(destructiveAction)
        
        // UIAlertControllerの起動
        present(alertController, animated: true, completion: nil)
    }
    
    func reproduce_cubes() {
        for cube in cubes {
            let cube_array = cube.split(separator: "_")
            if cube_array.count == 4 {
                changeLight(x: Float(cube_array[0])!, y: Float(cube_array[1])!, z: Float(cube_array[2])!, intensity: Float(cube_array[3])!)
            } else if cube_array.count == 9 {
                basicShape = String(cube_array[8])
                changeCubeSize(magnification: Float(cube_array[7])!)
                setAlpha(a: Float(cube_array[6])!)
                setColor(r: Int(cube_array[3])!, g: Int(cube_array[4])!, b: Int(cube_array[5])!)
                setCube(x: Float(cube_array[0])!, y: Float(cube_array[1])!, z: Float(cube_array[2])!)
            } else {
                receivingStatusMessage(text: "unknown data recieved from ".localized + "\(String(describing: sender_id))")
            }
            
        }
        
        // Remember who provided the map for showing UI feedback.
        mapProvider = sender_id as? MCPeerID
    }
    
    func receivingStatusMessage(text: String) {
        //self.receivingStatusLabel.isHidden = false
        self.receivingStatusLabel.text = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            // Put your code which should be executed with a delay here
            //self.roomIDLabel.text = "ID: " + self.roomId
            self.receivingStatusLabel.text = ""
        }
    }
    
    // MARK: - AR session management
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            if multipeerState {
                message = "Move around to map the environment, or wait to join a shared session.".localized
            } else {
                message = "Move around to map the environment and set AR planes".localized
            }
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            if multipeerState {
                message = "Connected with ".localized + "\(peerNames)."
                
            } else {
                message = ""
            }
            
        case .notAvailable:
            message = "Tracking unavailable.".localized
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly.".localized
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions.".localized
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received data from ".localized + "\(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted.".localized
            
        case .limited(.initializing):
            message = "Initializing AR session.".localized
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    
    @IBAction func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.reset()
        originPosition = nil
        // remove origin
        xAxisNode.removeFromParentNode()
        yAxisNode.removeFromParentNode()
        zAxisNode.removeFromParentNode()
    }
}


extension String {
    public func isOnly(_ characterSet: CharacterSet) -> Bool {
        return self.trimmingCharacters(in: characterSet).count <= 0
    }
    public func isOnlyNumeric() -> Bool {
        return isOnly(.decimalDigits)
    }
    public func isOnlyPunctuation() -> Bool {
        return isOnly(.punctuationCharacters)
    }
    public func isOnly(_ characterSet: CharacterSet, _ additionalString: String) -> Bool {
        var replaceCharacterSet = characterSet
        replaceCharacterSet.insert(charactersIn: additionalString)
        return isOnly(replaceCharacterSet)
    }
    /// StringからCharacterSetを取り除く
    func remove(characterSet: CharacterSet) -> String {
        return components(separatedBy: characterSet).joined()
    }
    /// StringからCharacterSetを抽出する
    func extract(characterSet: CharacterSet) -> String {
        return remove(characterSet: characterSet.inverted)
    }
}

// xAxis
class ConeNodeX: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        let cone = SCNCone(topRadius: 0.0, bottomRadius: 0.002, height: 0.1)
        cone.firstMaterial?.diffuse.contents = UIColor.red
        geometry = cone
        self.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 0, 0, 1)
        let h = self.boundingBox.max.y
        self.position = SCNVector3(h, 0, 0)
    }
}

// yAxis
class ConeNodeY: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        let cone = SCNCone(topRadius: 0.0, bottomRadius: 0.002, height: 0.1)
        cone.firstMaterial?.diffuse.contents = UIColor.green
        geometry = cone
        let h = self.boundingBox.max.y
        self.position = SCNVector3(0, h, 0)
    }
}

// zAxis
class ConeNodeZ: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
        let cone = SCNCone(topRadius: 0.0, bottomRadius: 0.002, height: 0.1)
        cone.firstMaterial?.diffuse.contents = UIColor.blue
        geometry = cone
        self.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, -1, 0, 0)
        let h = self.boundingBox.max.y
        self.position = SCNVector3(0, 0, h)
    }
}

// Cube
class CubeNode: SCNNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(CUBE_SIZE: Float, red: Int, green: Int, blue: Int, alpha: Float) {
        super.init()
        let cube = SCNBox(width: CGFloat(CUBE_SIZE), height: CGFloat(CUBE_SIZE), length: CGFloat(CUBE_SIZE), chamferRadius: 0)
        cube.firstMaterial?.diffuse.contents  = UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha))
        geometry = cube
        let h = self.boundingBox.max.y
        self.position = SCNVector3(h/2.0, h/2.0, h/2.0)
    }
}

// Sphere
class SphereNode: SCNNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(CUBE_SIZE: Float, red: Int, green: Int, blue: Int, alpha: Float) {
        super.init()
        let sphere = SCNSphere(radius: CGFloat(CUBE_SIZE) / 2)
        sphere.firstMaterial?.diffuse.contents  = UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha))
        geometry = sphere
        let h = self.boundingBox.max.y
        self.position = SCNVector3(h/2.0, h/2.0, h/2.0)
    }
}

// Cylinder
class CylinderNode: SCNNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(CUBE_SIZE: Float, red: Int, green: Int, blue: Int, alpha: Float) {
        super.init()
        let cylinder = SCNCylinder(radius: CGFloat(CUBE_SIZE) / 2, height: CGFloat(CUBE_SIZE))
        cylinder.firstMaterial?.diffuse.contents  = UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha))
        geometry = cylinder
        let h = self.boundingBox.max.y
        self.position = SCNVector3(h/2.0, h/2.0, h/2.0)
    }
}

// Cone
class ConeNode: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(CUBE_SIZE: Float, red: Int, green: Int, blue: Int, alpha: Float) {
        super.init()
        let cone = SCNCone(topRadius: 0.0, bottomRadius: CGFloat(CUBE_SIZE) / 2, height: CGFloat(CUBE_SIZE))
        cone.firstMaterial?.diffuse.contents  = UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha))
        geometry = cone
        let h = self.boundingBox.max.y
        self.position = SCNVector3(h/2.0, h/2.0, h/2.0)
    }
}

// Pyramid
class PyramidNode: SCNNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(CUBE_SIZE: Float, red: Int, green: Int, blue: Int, alpha: Float) {
        super.init()
        let pyramid = SCNPyramid(width: CGFloat(CUBE_SIZE), height: CGFloat(CUBE_SIZE), length: CGFloat(CUBE_SIZE))
        pyramid.firstMaterial?.diffuse.contents  = UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha))
        geometry = pyramid
        let h = self.boundingBox.max.y
        self.position = SCNVector3(h/2.0, h/2.0, h/2.0)
    }
}

// light
class LightNode: SCNNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(intensity: Int) {
        super.init()
        let light = SCNLight()
        light.type = .omni
        light.intensity = CGFloat(intensity)
        light.castsShadow = true
        self.light = light
    }
}

// plane
class PlaneNode: SCNNode {
    
    var detection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(anchor: ARPlaneAnchor) {
        super.init()
        
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        plane.materials.first?.diffuse.contents = UIImage(named: "grid.png")
        let material = plane.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(anchor.extent.x, anchor.extent.z, 1)
        material?.diffuse.wrapS = SCNWrapMode.repeat
        material?.diffuse.wrapT = SCNWrapMode.repeat
        
        geometry = plane
        transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
    
    func update(anchor: ARPlaneAnchor) {
        
        let plane = geometry as! SCNPlane
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
        position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
}

extension String
{
    // 多言語対応
    // 対象言語の「Localizable.strings」ファイルがない場合は、(Base)が使用されます。
    // 指定の文字列が「Localizable.strings」にない場合は、commentが採用されます。本実装では元の文字列が選択されます。
    var localized: String
    {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: self)
    }
}
