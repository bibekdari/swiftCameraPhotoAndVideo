//
//  ViewController.swift
//  Camera
//
//  Created by DARI on 4/5/16.
//  Copyright © 2016 DARI. All rights reserved.
//

import UIKit
import AVFoundation

class ViewControllerY: UIViewController {
    
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
    var PhotoPath: NSURL!
    var preset = AVCaptureSessionPresetPhoto
    
    var currentPosition: AVCaptureDevicePosition = .Back
    
    var sessionQueue: dispatch_queue_t!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSession()
    }
    
    func resetAll(){
        stillImageOutput = nil
        previewLayer = nil
        videoFileOutput = nil
        captureSession = nil
        captureDevice = nil
        
        recording = false
    }
    
    func configureSession(){
        resetAll()
        if let _ = captureSession where captureSession.running {
            captureSession.stopRunning()
        }
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = preset
        
        self.sessionQueue = dispatch_queue_create("camera_session", DISPATCH_QUEUE_SERIAL)
        
        captureDevice = getDevice(currentPosition)
        beginSession()
        addAudioInputAndStillImageOutputInSession()
        //let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        
        videoFileOutput = AVCaptureMovieFileOutput()
        self.captureSession.addOutput(videoFileOutput)
    }
    
    @IBAction func takeVideoAction(sender: AnyObject) {
        //captureSession.stopRunning()
        if viewX.hidden{
            viewX.hidden = false
            return
        }
        if !self.recordingModePhoto {
            
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let filePath = documentsURL.URLByAppendingPathComponent("temp\(NSDate()).mov")
            
            do {
                try  NSFileManager.defaultManager().removeItemAtURL(filePath)
            }
            catch {
                print("Error on deleting file: \(error)")
            }
            
            if recording {
                self.videoFileOutput!.stopRecording()
                button.setTitle("Record", forState: .Normal)
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewControllerWithIdentifier("avPlayer") as! AVPlayC
                vc.url = self.videoFilePath
                self.presentViewController(vc, animated: true, completion: nil)
                
            }else {
                configureSession()
                self.videoFilePath = filePath
                button.setTitle("Recording", forState: .Normal)
                
                //let filePath = NSURL(fileURLWithPath: "filePath")
                //captureSession.startRunning()
                
                self.videoFileOutput!.startRecordingToOutputFileURL(self.videoFilePath, recordingDelegate: self)
            }
            self.recording = !self.recording
        } else {
            
            button.setTitle("Try Next", forState: .Normal)
            let connection = self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
            //captureSession.startRunning()
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (imageDataSampleBuffer, error) in
                if error == nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    
                    // the sample buffer also contains the metadata, in case we want to modify it
                    //let metadata:NSDictionary = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)).takeUnretainedValue()
                    
                    if let image = UIImage(data: imageData) {
                        
                        // save the image or do something interesting with it
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let filePath = documentsURL.URLByAppendingPathComponent("temp.jpg")
                        
                        imageData.writeToURL(filePath, atomically: true)
                        self.viewX.hidden = true
                        self.imageView.image = image
                    }
                }
            })
        }
    }
    
    @IBAction func avswitch(sender: UIButton) {
        captureSession.stopRunning()
        if self.recordingModePhoto {
            sender.setTitle("Video", forState: .Normal)
            self.preset = AVCaptureSessionPresetHigh
        }else {
            sender.setTitle("Photo", forState: .Normal)
            self.preset = AVCaptureSessionPresetPhoto
        }
        self.recordingModePhoto = !self.recordingModePhoto
        configureSession()
    }
    
    @IBAction func changeCamera(sender: UIButton) {
        captureSession.stopRunning()
        if self.currentPosition == .Back {
            let backDevice = getDevice(.Back)
            do {
                captureSession.removeInput(try AVCaptureDeviceInput(device: backDevice))
                let frontDevice = getDevice(.Front)
                self.captureDevice = frontDevice
                currentPosition = .Front
                configureSession()
                sender.setTitle("Front", forState: .Normal)
            }catch{
                print("Cant remove/Add input: \(error)")
            }
        }else {
            let frontDevice = getDevice(.Front)
            do {
                captureSession.removeInput(try AVCaptureDeviceInput(device: frontDevice))
                
                let backDevice = getDevice(.Front)
                self.captureDevice = backDevice
                currentPosition = .Back
                configureSession()
                sender.setTitle("back", forState: .Normal)
            }catch{
                print("Cant remove input: \(error)")
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
    
    func beginSession() {
        //var err : NSError? = nil
        //captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
        }catch{
            print(error)
        }
        //self.viewX.bringSubviewToFront(button)
        //self.imageView.hidden = true
        //self.viewX.bringSubviewToFront(self.imageView)
        //self.viewX.bringSubviewToFront(self.backButton)
        //previewLayer?.frame = self.viewX.layer.frame
        
        //dispatch_async(sessionQueue) { () -> Void in
        self.captureSession.startRunning()
        //}
    }
    func addAudioInputAndStillImageOutputInSession(){
        let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        do {
            captureSession.addInput(try AVCaptureDeviceInput(device: audioDevice))
        }catch {
            print("Cant add audio: \(error)")
        }
        
        stillImageOutput = AVCaptureStillImageOutput()
        if self.captureSession.canAddOutput(self.stillImageOutput) {
            self.captureSession.addOutput(self.stillImageOutput)
        }
        //captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        //        if err != nil {
        //            print("error: \(err?.localizedDescription)")
        //        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = self.view.frame
        self.viewX.layer.addSublayer(previewLayer!)
    }
}

extension ViewControllerY: AVCaptureFileOutputRecordingDelegate {
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        return
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        return
    }
}

