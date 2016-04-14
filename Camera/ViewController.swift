//
//  ViewController.swift
//  Camera
//
//  Created by DARI on 4/5/16.
//  Copyright © 2016 DARI. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var viewX: UIView!
    
    @IBOutlet weak var button: UIButton!
    
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoFileOutput: AVCaptureMovieFileOutput?
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice?
    var recordingModePhoto = true
    var recording = false
    var videoFilePath: NSURL!
    
    var currentPosition: AVCaptureDevicePosition = .Back
    
    var sessionQueue: dispatch_queue_t!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadCamera()
    }
    
    func reloadCamera(){
        captureSession = AVCaptureSession()
        videoFileOutput = AVCaptureMovieFileOutput()
        stillImageOutput = AVCaptureStillImageOutput()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        captureDevice = getDevice(currentPosition)
        if let _ = captureDevice {
            beginSession()
        }
    }
    
    func beginSession() {
        do {
            captureSession.addInput( try AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("Cant get input : \(error)")
        }
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        do {
            captureSession.addInput(try AVCaptureDeviceInput(device: audioDevice))
        }catch {
            print("Cant add audio: \(error)")
        }
        
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.viewX.layer.addSublayer(previewLayer!)
        self.viewX.bringSubviewToFront(button)
        self.viewX.bringSubviewToFront(self.imageView)
        previewLayer?.frame = self.view.layer.frame
        
        captureSession.startRunning()
    }
    
    @IBAction func takeVideoAction(sender: UIButton) {
        if viewX.hidden {
            viewX.hidden = false
            return
        }
        if recordingModePhoto {
            sender.setTitle("Capturing", forState: .Normal)
            let connection = self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
            
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (imageDataSampleBuffer, error) in
                if error == nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    
                    if let image = UIImage(data: imageData) {
                        
                        // save the image or do something interesting with it
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let filePath = documentsURL.URLByAppendingPathComponent("temp.jpg")
                        
                        imageData.writeToURL(filePath, atomically: true)
                        self.viewX.hidden = true
                        self.imageView.image = image
                        sender.setTitle("Try Again", forState: .Normal)
                    }
                }
            })
        }else{
            if self.recording {
                self.videoFileOutput?.stopRecording()
                sender.setTitle("Record", forState: .Normal)
            }else {
                recording = true
                sender.setTitle("Recording", forState: .Normal)
                if captureSession.canAddOutput(videoFileOutput){
                    self.captureSession.addOutput(videoFileOutput)
                }
                
                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                let filePath = documentsURL.URLByAppendingPathComponent("temp.mov")
                self.videoFilePath = filePath
                
                do{
                    try NSFileManager.defaultManager().removeItemAtURL(filePath)
                }catch {
                    print("Cant delete file: \(error)")
                }
                videoFileOutput?.startRecordingToOutputFileURL(filePath, recordingDelegate: self)
            }
        }
    }
    
    @IBAction func avswitch(sender: UIButton) {
        if let recording = videoFileOutput?.recording where recording{
            self.recording = false
            videoFileOutput?.stopRecording()
        }
        if recordingModePhoto {
            sender.setTitle("Video", forState: .Normal)
        }else {
            sender.setTitle("Image", forState: .Normal)
        }
        recordingModePhoto = !recordingModePhoto
    }
    
    @IBAction func changeCamera(sender: UIButton) {
        
        if let recording = videoFileOutput?.recording where recording {
            videoFileOutput?.stopRecording()
            self.recording = false
        }
        
        captureSession.stopRunning()
        do {
            captureSession.removeInput(try AVCaptureDeviceInput(device: self.captureDevice))
        } catch {
            captureSession.startRunning()
            
            print("cant reove capture device from session: \(error)")
            return
        }
        
        switch self.currentPosition {
        case .Back:
            sender.setTitle("Front", forState: .Normal)
            currentPosition = .Front
        default:
            sender.setTitle("Back", forState: .Normal)
            currentPosition = .Back
        }
        reloadCamera()
    }
    
    @IBAction func flashSwitch(sender: UIButton) {
        if let flash = captureDevice?.hasFlash where flash {
            do {
                try captureDevice!.lockForConfiguration()
                
                switch captureDevice!.flashMode {
                case .Auto:
                    captureDevice?.flashMode = .Off
                    sender.setTitle("Flash Off", forState: .Normal)
                case .Off:
                    captureDevice?.flashMode = .On
                    sender.setTitle("Flash On", forState: .Normal)
                case .On:
                    captureDevice?.flashMode = .Auto
                    sender.setTitle("Flash Auto", forState: .Normal)
                }
                
//                if (captureDevice!.torchMode == .On) {
//                    captureDevice!.torchMode = .Off
//                    
//                } else {
//                    try captureDevice!.setTorchModeOnWithLevel(1.0)
//                }
                captureDevice!.unlockForConfiguration()
            } catch {
                print("cant lock the device \(error)")
            }
        }
    }
    func getDevice(position :AVCaptureDevicePosition)-> AVCaptureDevice{
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if(device.position == position) {
                    if let device = device as? AVCaptureDevice {
                        return device
                    }
                }
            }
        }
        return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if !recording {
            return
        }
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewControllerWithIdentifier("avPlayer") as! AVPlayC
        vc.url = self.videoFilePath
        self.presentViewController(vc, animated: true, completion: nil)
        
        recording = false
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        return
    }
}

