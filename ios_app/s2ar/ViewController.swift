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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    let manager = SocketManager(socketURL: URL(string: "http://s2ar-helper.glitch.me")!, config: [.log(true), .compress])
    var settingOrigin: Bool = true

    var xAxisNode: SCNNode!
    var yAxisNode: SCNNode!
    var zAxisNode: SCNNode!
    var originPosition: SCNVector3!
    
    var cubeNode: SCNNode!
    var cubeNodes: [String:SCNNode] = [:]

    var lightNode: SCNNode!
    var backLightNode: SCNNode!
    
    var planeNode: SCNNode!
    var planeNodes: [UUID:SCNNode] = [:]
    
    var red: Int = 255
    var green: Int = 255
    var blue: Int = 255
    
    var roomId: String = "0000 0000"
    let CUBE_SIZE: Float = 0.02
    
    var timer = Timer()
    
    @IBOutlet var roomIDLabel: UILabel!
    
    @IBOutlet var togglePlanesButton: UIButton!

    func setCube(x: Int, y: Int, z: Int) {
        if (originPosition == nil) {
            return
        }
        func setCubeMethod(x: Int, y: Int, z: Int) {
            let cube = SCNBox(width: CGFloat(CUBE_SIZE), height: CGFloat(CUBE_SIZE), length: CGFloat(CUBE_SIZE), chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents  = UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
            cubeNode = SCNNode(geometry: cube)
            cubeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            let position = SCNVector3Make(
                originPosition.x + Float(x) * CUBE_SIZE,
                originPosition.y + Float(y) * CUBE_SIZE,
                originPosition.z + Float(z) * CUBE_SIZE
            )
            cubeNode.position = position
            sceneView.scene.rootNode.addChildNode(cubeNode)
            cubeNodes[String(x) + "_" + String(y) + "_" + String(z)] = cubeNode
        }
        if cubeNodes.keys.contains(String(x) + "_" + String(y) + "_" + String(z)) {
            // remove cube if contains
            self.removeCube(x: x, y: y, z: z)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                // set cube
                setCubeMethod(x: x, y: y, z: z)
            }
                /*
            Thread.sleep(forTimeInterval: 0.01)
            // set cube
            setCubeMethod(x: x, y: y, z: z)
            */
        } else {
            // set cube
            setCubeMethod(x: x, y: y, z: z)
        }
    }
    
    func setBox(x: Int, y: Int, z: Int, w: Int, d: Int, h: Int) {
        if (originPosition == nil) {
            return
        }
        
        for k in 0...d {
            for j in 0...h {
                for i in 0...w {
                    self.setCube(x: x + i, y: y + j, z: z + k)
                }
            }
        }
    }
    
    func setCylinder(x: Int, y: Int, z: Int, r: Int, h: Int, a: String) {
        if (originPosition == nil) {
            return
        }
        
        switch a {
        case "x":
            for k in -r...r {
                for j in -r...r {
                    for i in 0..<h {
                        if (j * j + k * k < r * r) {
                            self.setCube(x: x + i, y: y + j, z: z + k)
                        }
                    }
                }
            }
        case "y":
            for k in -r...r {
                for j in 0..<h {
                    for i in -r...r {
                        if (i * i + k * k < r * r) {
                            self.setCube(x: x + i, y: y + j, z: z + k)
                        }
                    }
                }
            }
        case "z":
            for k in 0..<h {
                for j in -r...r {
                    for i in -r...r {
                        if (i * i + j * j < r * r) {
                            self.setCube(x: x + i, y: y + j, z: z + k)
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func setHexagon(x: Int, y: Int, z: Int, r: Int, h: Int, a: String) {
        if (originPosition == nil) {
            return
        }
        
        switch a {
        case "x":
            for k in 0...r {
                for j in 0...r {
                    for i in 0..<h {
                        if ((Double(j) <= cos(Double.pi / 6) * Double(r)) && (Double(j) <= -tan(Double.pi / 3) * Double(k) + tan(Double.pi / 3) * Double(r))) {
                            self.setCube(x: x + i, y: y + j, z: z + k)
                            self.setCube(x: x + i, y: y - j, z: z + k)
                            self.setCube(x: x + i, y: y - j, z: z - k)
                            self.setCube(x: x + i, y: y + j, z: z - k)
                        }
                    }
                }
            }
        case "y":
            for k in 0...r {
                for j in 0..<h {
                    for i in 0...r {
                        if ((Double(k) <= cos(Double.pi / 6) * Double(r)) && (Double(k) <= -tan(Double.pi / 3) * Double(i) + tan(Double.pi / 3) * Double(r))) {
                            self.setCube(x: x + i, y: y + j, z: z + k)
                            self.setCube(x: x - i, y: y + j, z: z + k)
                            self.setCube(x: x - i, y: y + j, z: z - k)
                            self.setCube(x: x + i, y: y + j, z: z - k)
                        }
                    }
                }
            }
        case "z":
            for k in 0..<h {
                for j in 0...r {
                    for i in 0...r {
                        if ((Double(j) <= cos(Double.pi / 6) * Double(r)) && (Double(j) <= -tan(Double.pi / 3) * Double(i) + tan(Double.pi / 3) * Double(r))) {
                            self.setCube(x: x + i, y: y + j, z: z + k)
                            self.setCube(x: x - i, y: y + j, z: z + k)
                            self.setCube(x: x - i, y: y - j, z: z + k)
                            self.setCube(x: x + i, y: y - j, z: z + k)
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func setSphere(x: Int, y: Int, z: Int, r: Int) {
        if (originPosition == nil) {
            return
        }
        
        for k in -r...r {
            for j in -r...r {
                for i in -r...r {
                    if (i * i + j * j + k * k < r * r) {
                        self.setCube(x: x + i, y: y + j, z: z + k)
                    }
                }
            }
        }
    }
    
    func setChar(x: Int, y: Int, z: Int, c: String, a: String) {
        if (originPosition == nil) {
            return
        }
        var k = 0
        let char:String! = Chars.chars[c]

        switch (a) {
        case "x":
            for j in 0..<8 {
                for i in 0..<8 {
                    var flag = char[char.index(char.startIndex, offsetBy: k)..<char.index(char.startIndex, offsetBy: k + 1)]
                    if (flag == "1") {
                        self.setCube(x: x, y: y - j, z: z + i)
                    }
                    k += 1
                }
            }
        case "y":
            for j in 0..<8 {
                for i in 0..<8 {
                    var flag = char[char.index(char.startIndex, offsetBy: k)..<char.index(char.startIndex, offsetBy: k + 1)]
                    if (flag == "1") {
                        self.setCube(x: x + i, y: y, z: z - j)
                    }
                    k += 1
                }
            }
        case "z":
            for j in 0..<8 {
                for i in 0..<8 {
                    var flag = char[char.index(char.startIndex, offsetBy: k)..<char.index(char.startIndex, offsetBy: k + 1)]
                    if (flag == "1") {
                        self.setCube(x: x + i, y: y - j, z: z)
                    }
                    k += 1
                }
            }
        default:
            break
        }
    }
    
    func setLine(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int) {
        if (originPosition == nil) {
            return
        }

        var vector = [x2 - x1, y2 - y1, z2 - z1]
        var vector2 = [abs(x2 - x1), abs(y2 - y1), abs(z2 - z1)]
        
        let index:Int? = vector2.index(of: vector2.max()!)
        
        switch (index) {
        case 0:
            for i in 0...vector2[0] {
                if (x2 > x1) {
                    self.setCube(x: x1 + i, y: y1 + vector[1] * i / vector[0], z: z1 + vector[2] * i / vector[0])
                } else {
                    self.setCube(x: x2 + i, y: y2 + vector[1] * i / vector[0], z: z2 + vector[2] * i / vector[0])
                }
            }
        case 1:
            for i in 0...vector2[1] {
                if (y2 > y1) {
                    self.setCube(x: x1 + vector[0] * i / vector[1], y: y1 + i, z: z1 + vector[2] * i / vector[1])
                } else {
                    self.setCube(x: x2 + vector[0] * i / vector[1], y: y2 + i, z: z2 + vector[2] * i / vector[1])
                }
            }
        case 2:
            for i in 0...vector2[2] {
                if (z2 > z1) {
                    self.setCube(x: x1 + vector[0] * i / vector[2], y: y1 + vector[1] * i / vector[2], z: z1 + i)
                } else {
                    self.setCube(x: x2 + vector[0] * i / vector[2], y: y2 + vector[1] * i / vector[2], z: z2 + i)
                }
            }
        default:
            break
        }
    }

    func setRoof(_x: Int, _y: Int, _z: Int, w: Int, d: Int, h: Int, a: String) {
        if (originPosition == nil) {
            return
        }
        
        switch (a) {
        case "x":
            if (w % 2 == 0) {
                if (abs(h) <= w / 2) {
                    for j in 0..<w {
                        let y:Int
                        if (j < w / 2) {
                            y = _y + 2 * (h - 1) * j / (w - 2)
                        } else {
                            y = _y - 2 * (h - 1) * (j - w + 1) / (w - 2)
                        }
                        for i in _x..<(_x + d) {
                            self.setCube(x: i, y: y, z: _z + j)
                        }
                    }
                } else {
                    for j in 0..<h {
                        for i in _z..<(_z + d) {
                            self.setCube(x: i, y: _y + j, z: (_z + (w - 2) * j / (2 * (h - 1))))
                        }
                        for i in _x..<(_x + d) {
                            self.setCube(x: i, y: _y + j, z: (_z - (w - 2) * j / (2 * (h - 1)) + w - 1))
                        }
                    }
                }
            } else {
                if (abs(h) <= (w + 1) / 2) {
                    for j in 0..<w {
                        let y:Int
                        if (j < w / 2) {
                            y = _y + 2 * (h - 1) * j / (w - 1)
                        } else {
                            y = _y - 2 * (h - 1) * (j - w + 1) / (w - 1)
                        }
                        for i in _x..<(_x + d) {
                            self.setCube(x: i, y: y, z: _z + j)
                        }
                    }
                } else {
                    for j in 0..<h {
                        for i in _x..<(_x + d) {
                            self.setCube(x: i, y: _y + j, z: (_z + (w - 1) * j / (2 * (h - 1))))
                        }
                        for i in _x..<(_x + d) {
                            self.setCube(x: i, y: _y + j, z: (_z - (w - 1) * (j - 2 * h + 2) / (2 * (h - 1))))
                        }
                    }
                }
            }
        case "y":
            if (w % 2 == 0) {
                if (abs(h) <= w / 2) {
                    for j in 0..<w {
                        let z:Int
                        if (j < w / 2) {
                            z = _z + 2 * (h - 1) * j / (w - 2)
                        } else {
                            z = _z - 2 * (h - 1) * (j - w + 1) / (w - 2)
                        }
                        for i in _y..<(_y + d) {
                            self.setCube(x: _x + j, y: i, z: z)
                        }
                    }
                } else {
                    for j in 0..<h {
                        for i in _y..<(_y + d) {
                            self.setCube(x: (_x + (w - 2) * j / (2 * (h - 1))), y: i, z: _z + j)
                        }
                        for i in _y..<(_y + d) {
                            self.setCube(x: (_x - (w - 2) * j / (2 * (h - 1)) + w - 1), y: i, z: _z + j)
                        }
                    }
                }
            } else {
                if (abs(h) <= (w + 1) / 2) {
                    for j in 0..<w {
                        let z:Int
                        if (j < w / 2) {
                            z = _z + 2 * (h - 1) * j / (w - 1)
                        } else {
                            z = _z - 2 * (h - 1) * (j - w + 1) / (w - 1)
                        }
                        for i in _y..<(_y + d) {
                            self.setCube(x: _x + j, y: i, z: z)
                        }
                    }
                } else {
                    for j in 0..<h {
                        for i in _y..<(_y + d) {
                            self.setCube(x: (_x + (w - 1) * j / (2 * (h - 1))), y: i, z: _z + j)
                        }
                        for i in _y..<(_y + d) {
                            self.setCube(x: (_x - (w - 1) * (j - 2 * h + 2) / (2 * (h - 1))), y: i, z: _z + j)
                        }
                    }
                }
            }
        case "z":
            if (w % 2 == 0) {
                if (abs(h) <= w / 2) {
                    for j in 0..<w {
                        let y:Int
                        if (j < w / 2) {
                            y = _y + 2 * (h - 1) * j / (w - 2)
                        } else {
                            y = _y - 2 * (h - 1) * (j - w + 1) / (w - 2)
                        }
                        for i in _z..<(_z + d) {
                            self.setCube(x: _x + j, y: y, z: i)
                        }
                    }
                } else {
                    for j in 0..<h {
                        for i in _z..<(_z + d) {
                            self.setCube(x: (_x + (w - 2) * j / (2 * (h - 1))), y: _y + j, z: i)
                        }
                        for i in _z..<(_z + d) {
                            self.setCube(x: (_x - (w - 2) * j / (2 * (h - 1)) + w - 1), y: _y + j, z: i)
                        }
                    }
                }
            } else {
                if (abs(h) <= (w + 1) / 2) {
                    for j in 0..<w {
                        let y:Int
                        if (j < w / 2) {
                            y = _y + 2 * (h - 1) * j / (w - 1)
                        } else {
                            y = _y - 2 * (h - 1) * (j - w + 1) / (w - 1)
                        }
                        for i in _z..<(_z + d) {
                            self.setCube(x: _x + j, y: y, z: i)
                        }
                    }
                } else {
                    for j in 0..<h {
                        for i in _x..<(_x + d) {
                            self.setCube(x: (_x + (w - 1) * j / (2 * (h - 1))), y: _y + j, z: i)
                        }
                        for i in _x..<(_x + d) {
                            self.setCube(x: (_x - (w - 1) * (j - 2 * h + 2) / (2 * (h - 1))), y: _y + j, z: i)
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func polygonFileFormat(x: Int, y: Int, z: Int, ply_file: String) {
        if (originPosition == nil) {
            return
        }
        let roop: Int
        //let _roop: int
        var ply2 = [[String]]()
        
        func createModel() {
            var vertex1: [String]
            var vertex2: [String]
            var vertex3: [String]
            var _x: Int
            var _y: Int
            var _z: Int
            for i in 0 ..< roop {
                vertex1 = ply2[4 * i]
                vertex2 = ply2[4 * i + 1]
                vertex3 = ply2[4 * i + 2]
                self.setColor(r: Int(vertex1[3])!, g: Int(vertex1[4])!, b: Int(vertex1[5])!)
                if vertex1[0] == vertex2[0] && vertex2[0] == vertex3[0] {// y-z plane
                    if vertex1[1] == vertex2[1] {
                        _x = x + Int(Double(vertex1[0])!)
                        _y = y + Int(Double(vertex1[2])!)
                        _z = z - Int(Double(vertex1[1])!)
                        if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                            // does not contains key
                            self.setCube(x: _x, y: _y, z: _z)
                        }
                    } else {
                        _x = x + Int(Double(vertex1[0])!) - 1
                        _y = y + Int(Double(vertex1[2])!)
                        _z = z - Int(Double(vertex1[1])!)
                        if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                            // does notcontains key
                            self.setCube(x: _x, y: _y, z: _z)
                        }
                    }
                } else if vertex1[1] == vertex2[1] && vertex2[1] == vertex3[1] {//z-x plane
                    if vertex1[2] == vertex2[2] {
                        _x = x + Int(Double(vertex1[0])!)
                        _y = y + Int(Double(vertex1[2])!)
                        _z = z - Int(Double(vertex1[1])!)
                        if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                            // does notcontains key
                            self.setCube(x: _x, y: _y, z: _z)
                        }
                    } else {
                        _x = x + Int(Double(vertex1[0])!)
                        _y = y + Int(Double(vertex1[2])!)
                        _z = z - Int(Double(vertex1[1])!) + 1
                        if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                            // does notcontains key
                            self.setCube(x: _x, y: _y, z: _z)
                        }
                    }
                } else {//x-y plane
                    if vertex1[0] == vertex2[0] {
                        _x = x + Int(Double(vertex1[0])!)
                        _y = y + Int(Double(vertex1[2])!)
                        _z = z - Int(Double(vertex1[1])!)
                        if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                            // does notcontains key
                            self.setCube(x: _x, y: _y, z: _z)
                        }
                    } else {
                        _x = x + Int(Double(vertex1[0])!)
                        _y = y + Int(Double(vertex1[2])!) - 1
                        _z = z - Int(Double(vertex1[1])!)
                        if !(cubeNodes.keys.contains(String(_x) + "_" + String(_y) + "_" + String(_z))) {
                            // does notcontains key
                            self.setCube(x: _x, y: _y, z: _z)
                        }
                    }
                }
            }
        }
        
        if ply_file.contains("ply") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_ply_file = dir.appendingPathComponent( ply_file )
                do {
                    let ply = try String( contentsOf: path_ply_file, encoding: String.Encoding.utf8 )
                    var tempArray = ply.components(separatedBy: "\r\n")
                    if tempArray.count == 1 {
                        tempArray = ply.components(separatedBy: "\n")
                    }
                    //roop = arr[11].components(separatedBy: " ")
                    roop = Int(tempArray[11].components(separatedBy: " ")[2])!
                    for i in 0 ..< 4 * roop {
                        ply2.append(tempArray[14 + i].components(separatedBy: " "))
                    }
                    createModel()
                } catch {
                    //error message
                    self.roomIDLabel.text = "Not such a file"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // Put your code which should be executed with a delay here
                        self.roomIDLabel.text = "Connected !"
                    }
                }
            }
        } else {
            let tempArray = ply_file.components(separatedBy: " ")
            var tempArray2: [String] = []
            roop = tempArray.count / 24
            for i in 0 ..< 4 * roop {
                for j in 0 ..< 6 {
                    tempArray2.append(tempArray[6 * i + j])
                }
                ply2.append(tempArray2)
                tempArray2 = []
            }
            createModel()
        }
    }
    
    func animation(x: Int, y: Int, z: Int, differenceX: Int, differenceY: Int, differenceZ: Int, time: Double, times: Int, files: String) {
        if (originPosition == nil) {
            return
        }

        let plys = files.components(separatedBy: ",")
        if plys[0].contains("ply") {
            var i = 0
            timer = Timer.scheduledTimer(withTimeInterval: time, repeats: true, block: { (timer) in
                self.polygonFileFormat(x: x + i * differenceX, y: y + i * differenceY, z: z + i * differenceZ, ply_file: plys[i % plys.count])
                DispatchQueue.main.asyncAfter(deadline: .now() + time * 4 / 5) {
                    // Put your code which should be executed with a delay here
                    self.reset()
                }
                i += 1
                if (i >= times) {
                    timer.invalidate()
                }
            })
        } else {
            //error message
            self.roomIDLabel.text = "Not such a file"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Put your code which should be executed with a delay here
                self.roomIDLabel.text = "Connected !"
            }
        }
    }
    
    func map(map_data: String, width: Int, height: Int, magnification: Double, r1: Int, g1: Int, b1: Int, r2: Int, g2: Int, b2: Int, upward: Int) {
        if (originPosition == nil) {
            return
        }
        //print("mapping...")
        var elevation: Int
        var _map2 = [[String]]()
        var map2 = [[String]]()
        var maps: [String] = []
        var _maps: [String] = []
        var tempArray: [String] = []
        var gap: Int // to fill the gap
        var maxY: Int
        var minY: Int
        
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
            if _y > 0 {
                heightSetColor(y: _y, minY: minY, maxY: maxY)
                self.setCube(x: _x, y: _y + upward, z: _z)
                if gap > 1 {
                    for k in 1 ... gap - 1 {
                        heightSetColor(y: _y - k, minY: minY, maxY: maxY)
                        self.setCube(x: _x, y: _y - k + upward, z: _z)
                    }
                }
            } else if _y < 0{
                heightSetColor(y: _y, minY: minY, maxY: maxY)
                self.setCube(x: _x, y: _y + 1 + upward, z: _z)
                if gap > 1 {
                    for k in 1 ... gap - 1 {
                        heightSetColor(y: _y - k, minY: minY, maxY: maxY)
                        self.setCube(x: _x, y: _y + 1 + k + upward, z: _z)
                    }
                }
            }
        }
        
        if map_data.contains("csv") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_csv_file = dir.appendingPathComponent( map_data )
                do {
                    let _map_data = try String( contentsOf: path_csv_file, encoding: String.Encoding.utf8 )
                    maps = _map_data.components(separatedBy: "\r\n")
                    if maps.count == 1 {
                        maps = _map_data.components(separatedBy: "\n")
                    }
                } catch {
                    //error message
                    self.roomIDLabel.text = "Not such a file"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // Put your code which should be executed with a delay here
                        self.roomIDLabel.text = "Connected !"
                    }
                }
            }
        } else {
            //Read from Scratch
            maps = map_data.components(separatedBy: " ")
        }
        //２次元配列に変換
        if maps.count == 1{
            for i in 0 ..< height {
                _maps = maps[0].components(separatedBy: ",")
                for j in 0 ..< width {
                    tempArray.append(_maps[i * width + j])
                }
                _map2.append(tempArray)
                tempArray = []
            }
        } else {
            for i in 0 ..< height {
                _map2.append(maps[i].components(separatedBy: ","))
            }
        }
        //前後にスペースが入っていたら消す。
        for i in 0 ..< height {
            for j in 0 ..< width {
                tempArray.append(_map2[i][j].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            map2.append(tempArray)
            tempArray = []
        }
        //y の最大値、最小値
        minY = Int(ceil(Double(map2[0][0])! * magnification))
        maxY = Int(ceil(Double(map2[0][0])! * magnification))
        for i in 0 ..< height {
            for j in 0 ..< width {
                if minY > Int(ceil(Double(map2[i][j])! * magnification)) {
                    minY = Int(ceil(Double(map2[i][j])! * magnification))
                }
                if maxY < Int(ceil(Double(map2[i][j])! * magnification)) {
                    maxY = Int(ceil(Double(map2[i][j])! * magnification))
                }
            }
        }
        
        for i in 0 ..< height {
            for j in 0 ..< width {
                elevation = Int(ceil(Double(map2[i][j])! * magnification))
                if elevation > 0 {
                    // Calculate gaps
                    if height == 1 {
                        if j == 0 {
                            gap = elevation - [Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                        } else if j == width - 1 {
                            gap = elevation - [Int(ceil(Double(map2[i][j - 1])! * magnification))].min()!
                        } else {
                            gap = elevation - [Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                        }
                    } else if i == 0 {
                        if j == 0 {
                            if width == 1 {
                                gap = elevation - [Int(ceil(Double(map2[i + 1][j])! * magnification))].min()!
                            } else {
                                gap = elevation - [Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                            }
                        } else if j == width - 1 {
                            gap = elevation - [Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification))].min()!
                        } else {
                            gap = elevation - [Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                        }
                    } else if i == height - 1 {
                        if j == 0 {
                            if width == 1 {
                                gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification))].min()!
                            } else {
                                gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                            }
                        } else if j == width - 1 {
                            gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification))].min()!
                        } else {
                            gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                        }
                    } else {
                        if j == 0 {
                            if width == 1 {
                                gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification))].min()!
                            } else {
                                gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                            }
                        } else if j == width - 1 {
                            gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification))].min()!
                        } else {
                            gap = elevation - [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].min()!
                        }
                    }
                } else {
                    // Calculate gaps
                    if height == 1 {
                        if j == 0 {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                        } else if j == width - 1 {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i][j - 1])! * magnification))].max()!
                        } else {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                        }
                    } else if i == 0 {
                        if j == 0 {
                            if width == 1 {
                                gap = 0 - elevation + [Int(ceil(Double(map2[i + 1][j])! * magnification))].max()!
                            } else {
                                gap = 0 - elevation + [Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                            }
                        } else if j == width - 1 {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification))].max()!
                        } else {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                        }
                    } else if i == height - 1 {
                        if j == 0 {
                            if width == 1 {
                                gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification))].max()!
                            } else {
                                gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                            }
                        } else if j == width - 1 {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification))].max()!
                        } else {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                        }
                    } else {
                        if j == 0 {
                            if width == 1 {
                                gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification))].max()!
                            } else {
                                gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                            }
                        } else if j == width - 1 {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification))].max()!
                        } else {
                            gap = 0 - elevation + [Int(ceil(Double(map2[i - 1][j])! * magnification)), Int(ceil(Double(map2[i + 1][j])! * magnification)), Int(ceil(Double(map2[i][j - 1])! * magnification)), Int(ceil(Double(map2[i][j + 1])! * magnification))].max()!
                        }
                    }
                    
                }
                drawMap(i: i, j: j, elevation: elevation, gap: gap, minY: minY, maxY: maxY, upward: upward)
            }
        }
    }
    
    func molecular_structure(x: Double, y: Double, z: Double, magnification: Double, mld_file: String) {
        if (originPosition == nil) {
            return
        }
        let roop1: Int
        let roop2: Int
        var position = [[String]]()
        var line = [[String]]()
        
        func createStructure() {
            var _x: Int
            var _y: Int
            var _z: Int
            var _r: Int
            var _x1: Int
            var _y1: Int
            var _z1: Int
            var _x2: Int
            var _y2: Int
            var _z2: Int
            for i in 0 ..< roop1 {
                switch (position[i][3]) {
                case "1": //Hydrogen
                    self.setColor(r: 255, g: 0, b: 0)
                case "6": //Carbon
                    self.setColor(r: 0, g: 255, b: 0)
                case "7": //Nitrogen
                    self.setColor(r: 0, g: 0, b: 255)
                case "8": //Oxygen
                    self.setColor(r: 255, g: 255, b: 0)
                case "9": //Fluorine
                    self.setColor(r: 0, g: 255, b: 255)
                case "14": //Silicon
                    self.setColor(r: 255, g: 0, b: 255)
                case "15": //Phosphorus
                    self.setColor(r: 255, g: 255, b: 255)
                default:
                    self.setColor(r: 0, g: 0, b: 0)
                    break
                }
                _x = Int(x + Double(position[i][0])! * magnification)
                _y = Int(y + Double(position[i][1])! * magnification)
                _z = Int(z + Double(position[i][2])! * magnification)
                _r = Int(0.3 * magnification)
                self.setSphere(x: _x, y: _y, z: _z, r: _r)
            }
            self.setColor(r: 0, g: 0, b: 0)
            for j in 0 ..< roop2 {
                _x1 = Int(x + Double(position[Int(line[j][0])! - 1][0])! * magnification)
                _y1 = Int(y + Double(position[Int(line[j][0])! - 1][1])! * magnification)
                _z1 = Int(z + Double(position[Int(line[j][0])! - 1][2])! * magnification)
                _x2 = Int(x + Double(position[Int(line[j][1])! - 1][0])! * magnification)
                _y2 = Int(y + Double(position[Int(line[j][1])! - 1][1])! * magnification)
                _z2 = Int(z + Double(position[Int(line[j][1])! - 1][2])! * magnification)
                self.setLine(x1: _x1, y1: _y1, z1: _z1, x2: _x2, y2: _y2, z2: _z2)
            }
        }
        
        if mld_file.contains("mld") {
            // Read ply file from iTunes File Sharing
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                let path_mld_file = dir.appendingPathComponent( mld_file )
                do {
                    let mld = try String( contentsOf: path_mld_file, encoding: String.Encoding.utf8 )
                    var tempArray = mld.components(separatedBy: "\r\n")
                    if tempArray.count == 1 {
                        tempArray = mld.components(separatedBy: "\n")
                    }
                    roop1 = Int(tempArray[1])!
                    for i in 0 ..< roop1 {
                        position.append(tempArray[2 + i].components(separatedBy: ","))
                    }
                    roop2 = Int(tempArray[2 + roop1])!
                    for i in 0 ..< roop2 {
                        line.append(tempArray[3 + roop1 + i].components(separatedBy: ","))
                    }
                    createStructure()
                } catch {
                    //error message
                    self.roomIDLabel.text = "Not such a file"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // Put your code which should be executed with a delay here
                        self.roomIDLabel.text = "Connected !"
                    }
                }
            }
        } else {
            let tempArray = mld_file.components(separatedBy: " ")
            roop1 = Int(tempArray[1])!
            for i in 0 ..< roop1 {
                position.append(tempArray[2 + i].components(separatedBy: ","))
            }
            roop2 = Int(tempArray[2 + roop1])!
            for i in 0 ..< roop2 {
                line.append(tempArray[3 + roop1 + i].components(separatedBy: ","))
            }
            createStructure()
        }
    }
    
    func setColor(r: Int, g: Int, b: Int) {
        if (originPosition == nil) {
            return
        }
        
        red = r
        green = g
        blue = b
    }
    
    func removeCube(x: Int, y: Int, z: Int) {
        if (originPosition == nil) {
            return
        }
        
        let cubeNode = cubeNodes[String(x) + "_" + String(y) + "_" + String(z)]
        if (cubeNode == nil) {
            return
        }
    
        cubeNode?.removeFromParentNode()
        //message
        self.roomIDLabel.text = "Remove a cube"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Put your code which should be executed with a delay here
            self.roomIDLabel.text = "Connected !"
        }
    }
    
    func reset() {
        if (originPosition == nil) {
            return
        }
        //message
        self.roomIDLabel.text = "Reset"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Put your code which should be executed with a delay here
            self.roomIDLabel.text = "Connected !"
        }
        
        for (id, cubeNode) in cubeNodes {
            cubeNode.removeFromParentNode()
        }
        cubeNodes = [:]
    }
    
    @IBAction func togglePlanesButtonTapped(_ sender: UIButton) {
        if (self.settingOrigin) {
            self.settingOrigin = false
            self.xAxisNode?.isHidden = true
            self.yAxisNode?.isHidden = true
            self.zAxisNode?.isHidden = true
            
            togglePlanesButton.setTitle("Show Planes", for: .normal)
            
            for (identifier, planeNode) in planeNodes {
                planeNode.isHidden = true
            }
        } else {
            self.settingOrigin = true
            self.xAxisNode.isHidden = false
            self.yAxisNode.isHidden = false
            self.zAxisNode.isHidden = false

            togglePlanesButton.setTitle("Hide Planes", for: .normal)
            
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

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
                
        // Set the scene to the view
        sceneView.scene = SCNScene(named: "art.scnassets/main.scn")!
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        sceneView.autoenablesDefaultLighting = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapFrom))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // WebSocket
        let socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) {data, ack in
            self.roomId = String(format: "%04d", Int(arc4random_uniform(10000))) + "-" + String(format: "%04d", Int(arc4random_uniform(10000)))
            self.roomIDLabel.text = "ID: " + self.roomId
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
            self.roomIDLabel.text = "Connected !"
            if let msg = data[0] as? String {
                print(msg)
                let units = msg.components(separatedBy: ":")
                let action = units[0]
                switch action {
                case "set_cube":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    self.setCube(x: x!, y: y!, z: z!)
                case "set_box":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let w = Int(units[4])
                    let d = Int(units[5])
                    let h = Int(units[6])
                    self.setBox(x: x!, y: y!, z: z!, w: w!, d: d!, h: h!)
                case "set_cylinder":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let r = Int(units[4])
                    let h = Int(units[5])
                    let a = units[6]
                    self.setCylinder(x: x!, y: y!, z: z!, r: r!, h: h!, a: a)
                case "set_hexagon":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let r = Int(units[4])
                    let h = Int(units[5])
                    let a = units[6]
                    self.setHexagon(x: x!, y: y!, z: z!, r: r!, h: h!, a: a)
                case "set_sphere":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let r = Int(units[4])
                    self.setSphere(x: x!, y: y!, z: z!, r: r!)
                case "set_char":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let c = units[4]
                    let a = units[5]
                    self.setChar(x: x!, y: y!, z: z!, c: c, a: a)
                case "set_line":
                    let x1 = Int(units[1])
                    let y1 = Int(units[2])
                    let z1 = Int(units[3])
                    let x2 = Int(units[4])
                    let y2 = Int(units[5])
                    let z2 = Int(units[6])
                    self.setLine(x1: x1!, y1: y1!, z1: z1!, x2: x2!, y2: y2!, z2: z2!)
                case "set_roof":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let w = Int(units[4])
                    let d = Int(units[5])
                    let h = Int(units[6])
                    let a = units[7]
                    self.setRoof(_x: x!, _y: y!, _z: z!, w: w!, d: d!, h: h!, a: a)
                case "polygon_file_format":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let ply_file = units[4]
                    self.polygonFileFormat(x: x!, y: y!, z: z!, ply_file: ply_file)
                case "animation":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    let differenceX = Int(units[4])
                    let differenceY = Int(units[5])
                    let differenceZ = Int(units[6])
                    let time = Double(units[7])
                    let times = Int(units[8])
                    let files = units[9]
                    self.animation(x: x!, y: y!, z: z!, differenceX: differenceX!, differenceY: differenceY!, differenceZ: differenceZ!, time: time!, times: times!, files: files)
                case "map":
                    let map_data = units[1]
                    let width = Int(units[2])
                    let height = Int(units[3])
                    let magnification = Double(units[4])
                    let r1 = Int(units[5])
                    let g1 = Int(units[6])
                    let b1 = Int(units[7])
                    let r2 = Int(units[8])
                    let g2 = Int(units[9])
                    let b2 = Int(units[10])
                    let upward = Int(units[11])
                    self.map(map_data: map_data, width: width!, height: height!, magnification: magnification!, r1: r1!, g1: g1!, b1: b1!, r2: r2!, g2: g2!, b2: b2!, upward: upward!)
                case "molecular_structure":
                    let x = Double(units[1])
                    let y = Double(units[2])
                    let z = Double(units[3])
                    let magnification = Double(units[4])
                    let mld_file = units[5]
                    self.molecular_structure(x: x!, y: y!, z: z!, magnification: magnification!, mld_file: mld_file)
                case "set_color":
                    let r = Int(units[1])
                    let g = Int(units[2])
                    let b = Int(units[3])
                    self.setColor(r: r!, g: g!, b: b!)
                case "remove_cube":
                    let x = Int(units[1])
                    let y = Int(units[2])
                    let z = Int(units[3])
                    self.removeCube(x: x!, y: y!, z: z!)
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
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc func handleTapFrom(recognizer: UITapGestureRecognizer) {
        if !settingOrigin {
            return
        }
        let pos = recognizer.location(in: sceneView)
        let results = sceneView.hitTest(pos, types: .existingPlaneUsingExtent)
        if results.count == 0 {
            return
        }
        guard let hitResult = results.first else { return }
        
        if originPosition != nil {
            originPosition = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                            hitResult.worldTransform.columns.3.y,
                                            hitResult.worldTransform.columns.3.z)
            xAxisNode.position = SCNVector3Make(originPosition.x + CUBE_SIZE * 10, originPosition.y, originPosition.z)
            yAxisNode.position = SCNVector3Make(originPosition.x, originPosition.y + CUBE_SIZE * 10, originPosition.z)
            zAxisNode.position = SCNVector3Make(originPosition.x, originPosition.y, originPosition.z + CUBE_SIZE * 10)

            lightNode.position = SCNVector3Make(originPosition.x + CUBE_SIZE * 100,
                                                originPosition.y + CUBE_SIZE * 100,
                                                originPosition.z + CUBE_SIZE * 100)
            
            backLightNode.position = SCNVector3Make(originPosition.x - CUBE_SIZE * 100,
                                                originPosition.y + CUBE_SIZE * 100,
                                                originPosition.z - CUBE_SIZE * 100)
        } else {
            let xAxisGeometry = SCNCylinder(radius: CGFloat(CUBE_SIZE / 10.0), height: CGFloat(CUBE_SIZE * 20.0))
            xAxisGeometry.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            xAxisNode = SCNNode(geometry: xAxisGeometry)
            xAxisNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 0, 0, 1)

            let yAxisGeometry = SCNCylinder(radius: CGFloat(CUBE_SIZE / 10.0), height: CGFloat(CUBE_SIZE * 20.0))
            yAxisGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
            yAxisNode = SCNNode(geometry: yAxisGeometry)

            let zAxisGeometry = SCNCylinder(radius: CGFloat(CUBE_SIZE / 10.0), height: CGFloat(CUBE_SIZE * 20.0))
            zAxisGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            zAxisNode = SCNNode(geometry: zAxisGeometry)
            zAxisNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
            
            xAxisNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            yAxisNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            zAxisNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)

            originPosition = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                            hitResult.worldTransform.columns.3.y,
                                            hitResult.worldTransform.columns.3.z)
            
            xAxisNode.position = SCNVector3Make(originPosition.x + CUBE_SIZE * 10, originPosition.y, originPosition.z)
            yAxisNode.position = SCNVector3Make(originPosition.x, originPosition.y + CUBE_SIZE * 10, originPosition.z)
            zAxisNode.position = SCNVector3Make(originPosition.x, originPosition.y, originPosition.z + CUBE_SIZE * 10)
            
            sceneView.scene.rootNode.addChildNode(xAxisNode)
            sceneView.scene.rootNode.addChildNode(yAxisNode)
            sceneView.scene.rootNode.addChildNode(zAxisNode)
            
            let light = SCNLight()
            light.type = .directional
            light.intensity = 1000
            light.castsShadow = true
            
            lightNode = SCNNode()
            lightNode.light = light
            lightNode.position = SCNVector3Make(originPosition.x + CUBE_SIZE * 100,
                                               originPosition.y + CUBE_SIZE * 100,
                                               originPosition.z + CUBE_SIZE * 100)
        
            let constraint = SCNLookAtConstraint(target: xAxisNode)
            constraint.isGimbalLockEnabled = true
            
            lightNode.constraints = [constraint]
            sceneView.scene.rootNode.addChildNode(lightNode)

            let backLight = SCNLight()
            backLight.type = .directional
            backLight.intensity = 100
            light.castsShadow = true

            backLightNode = SCNNode()
            backLightNode.light = backLight
            backLightNode.position = SCNVector3Make(originPosition.x - CUBE_SIZE * 100,
                                                originPosition.y + CUBE_SIZE * 100,
                                                originPosition.z - CUBE_SIZE * 100)
            
            backLightNode.constraints = [constraint]
            sceneView.scene.rootNode.addChildNode(backLightNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        
        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                               height: CGFloat(planeAnchor.extent.z))
        
        geometry.materials.first?.diffuse.contents = UIImage(named: "grid.png")
        let material = geometry.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(planeAnchor.extent.x, planeAnchor.extent.z, 1)
        material?.diffuse.wrapS = SCNWrapMode.repeat
        material?.diffuse.wrapT = SCNWrapMode.repeat
        
        let planeNode = SCNNode(geometry: geometry)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        planeNode.isHidden = !settingOrigin
        
        planeNodes[anchor.identifier] = planeNode
        
        DispatchQueue.main.async(execute: {
          node.addChildNode(planeNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}

        let planeNode = planeNodes[anchor.identifier]
        if planeNode == nil {
            return
        }

        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                                height: CGFloat(planeAnchor.extent.z))

        geometry.materials.first?.diffuse.contents = UIImage(named: "grid.png")
        
        let material = geometry.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(planeAnchor.extent.x, planeAnchor.extent.z, 1)
        material?.diffuse.wrapS = SCNWrapMode.repeat
        material?.diffuse.wrapT = SCNWrapMode.repeat

        planeNode?.geometry = geometry
        planeNode?.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        planeNode?.isHidden = !settingOrigin

        planeNode?.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
        
        planeNodes[anchor.identifier] = planeNode
    }
}
