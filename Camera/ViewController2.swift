//
//  ViewController2.swift
//  Camera
//
//  Created by DARI on 4/12/16.
//  Copyright © 2016 DARI. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController2: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var takePhotoButton: UIButton!
    
    @IBOutlet weak var snappedPicture: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        beginSession()
                    }
                }
            }
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func beginSession() {
        do {
            captureSession.addInput( try AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("Cant get input : \(error)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.cameraView.layer.addSublayer(previewLayer!)
        self.cameraView.bringSubviewToFront(takePhotoButton)
        self.cameraView.bringSubviewToFront(self.snappedPicture)
        //self.cameraView.bringSubviewToFront(self.backButton)
        previewLayer?.frame = self.cameraView.layer.frame
        captureSession.startRunning()
    }
    
    @IBAction func takeVideoAction(sender: AnyObject) {
        
        var recordingDelegate:AVCaptureFileOutputRecordingDelegate? = self
        
        var videoFileOutput = AVCaptureMovieFileOutput()
        self.captureSession.addOutput(videoFileOutput)
        
        let filePath = NSURL(fileURLWithPath: "filePath")
        
        videoFileOutput.startRecordingToOutputFileURL(filePath, recordingDelegate: recordingDelegate)
        
    }
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        return
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        return
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
