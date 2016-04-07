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
    
    var currentPosition: AVCaptureDevicePosition = .Back
    
    var sessionQueue: dispatch_queue_t!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        self.sessionQueue = dispatch_queue_create("camera_session", DISPATCH_QUEUE_SERIAL)
        
        captureDevice = getDevice(.Back)
        beginSession()
        addAudioInputAndStillImageOutputInSession()
        //let recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        
        videoFileOutput = AVCaptureMovieFileOutput()
        self.captureSession.addOutput(videoFileOutput)
        
    }
    @IBAction func takeVideoAction(sender: AnyObject) {
        if viewX.hidden{
            viewX.hidden = false
            return
        }
        if !self.recordingModePhoto {
            
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let filePath = documentsURL.URLByAppendingPathComponent("temp.mov")
            
            if recording {
                self.videoFileOutput!.stopRecording()
                button.setTitle("Record", forState: .Normal)
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewControllerWithIdentifier("avPlayer") as! AVPlayC
                vc.url = filePath
                self.presentViewController(vc, animated: true, completion: nil)
                
            }else {
                button.setTitle("Recording", forState: .Normal)
                
                //let filePath = NSURL(fileURLWithPath: "filePath")
                
                self.videoFileOutput!.startRecordingToOutputFileURL(filePath, recordingDelegate: self)
            }
            self.recording = !self.recording
        } else {
            
            button.setTitle("Try Next", forState: .Normal)
            let connection = self.stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
            
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
        if self.recordingModePhoto {
            sender.setTitle("Video", forState: .Normal)
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
        }else {
            sender.setTitle("Photo", forState: .Normal)
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        }
        self.recordingModePhoto = !self.recordingModePhoto
    }
    
    @IBAction func changeCamera(sender: UIButton) {
        captureSession.stopRunning()
        if self.currentPosition == .Back {
            let backDevice = getDevice(.Back)
            do {
                captureSession.removeInput(try AVCaptureDeviceInput(device: backDevice))
                let frontDevice = getDevice(.Front)
                self.captureDevice = frontDevice
                beginSession()
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
                beginSession()
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

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        return
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        return
    }
}

