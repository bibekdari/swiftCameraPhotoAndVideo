//
//  CameraViewController.swift
//  Camera
//
//  Created by DARI on 4/8/16.
//  Copyright © 2016 DARI. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var buttonCapture: UIButton!
    
    //manages the data flow between the inputs and the outputs and error handling
    var session = AVCaptureSession()
    var cameraPosition: AVCaptureDevicePosition = .Back
    let videoOutput = AVCaptureVideoDataOutput()
    let stillCameraOutput = AVCaptureStillImageOutput()
    let sampleBufferQueue = dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL)
    let sessionQueue = dispatch_queue_create("session queue for camera of com.qwerty1234567.example.capture", DISPATCH_QUEUE_SERIAL)
    var cameraModeIsPhoto = true
    var currentDevice: AVCaptureDevice!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startSession()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func captureTouched(sender: UIButton) {
        if previewView.hidden {
            previewView.hidden = false
            return
        }
        sender.setTitle("Capture", forState: .Normal)
        if self.cameraModeIsPhoto {
            self.captureStillImage(sessionQueue)
            previewView.hidden = true
            sender.setTitle("Capturing", forState: .Normal)
        }
    }
    
    @IBAction func switchCamera(sender: UIButton) {
        dispatch_async(sessionQueue) { 
             self.session.stopRunning()
        }
        //var newDevice: AVCaptureDevice?
        
        switch self.cameraPosition {
        case .Back:
            //newDevice = self.getCameraDeviceOfSpecificPosition(AVMediaTypeVideo, position: .Front)
            sender.setTitle("Front", forState: .Normal)
            self.cameraPosition = .Front
        default:
            //newDevice = self.getCameraDeviceOfSpecificPosition(AVMediaTypeVideo, position: .Back)
            sender.setTitle("Back", forState: .Normal)
            self.cameraPosition = .Back
        }
//        if let newDevice = newDevice {
//            self.session.removeInput(getCaptureDeviceInputForCaptureDevice(currentDevice))
//            self.currentDevice = newDevice
//            self.session.addInput(getCaptureDeviceInputForCaptureDevice(newDevice))
//        }
        self.session = AVCaptureSession()
        
        self.startSession()
    }
    
    func startSession(){
        self.session.beginConfiguration()
        //if deviceAuthorizationCheck(AVMediaTypeVideo) || deviceAuthorizationCheck(AVMediaTypeAudio) {
        if let camera = self.getCameraDeviceOfSpecificPosition(AVMediaTypeVideo, position: self.cameraPosition), let audio = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio) {
            self.currentDevice = camera
            addInputDeviceToSession(getCaptureDeviceInputForCaptureDevice(audio)!, session: self.session)
            addCaptureOutputToSession(captureSession: self.session, captureOutput: self.stillCameraOutput)
            if let input = self.getCaptureDeviceInputForCaptureDevice(camera) {
                if self.addInputDeviceToSession(input, session: self.session) {
                    self.attachPreviewLayerToSession(self.session, viewToAddLayer: previewView)
                    self.addCaptureVideoOutputToSession(catpureSession: self.session, videoOutput: self.videoOutput, sampleBufferdelegateObject: self, queue: self.sampleBufferQueue)
                    self.addCaptureOutputToSession(captureSession: self.session, captureOutput: self.stillCameraOutput)
                    self.capturePresetForCaptureDevice(self.session, currentDevice: currentDevice, isOutputStillImage: self.cameraModeIsPhoto)
                    //since all actions and configs done on the session or the camera are blocking calls so its dispatched to background serial queue
                    dispatch_async(sessionQueue, {
                        self.session.startRunning()
                    })
                }
            }
        }
        self.session.commitConfiguration()
        //}
    }
    
    private func captureStillImage(queue: dispatch_queue_t){
        dispatch_async(queue) {
            let connection = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo)
            //update video orientation w.r.t. device
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue) ?? AVCaptureVideoOrientation.Portrait
            self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (imageDataSampleBuffer, error) in
                if error == nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let _: NSDictionary? = CMCopyDictionaryOfAttachments(nil, imageDataSampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
                    if let image = UIImage(data: imageData) {
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let filePath = documentsURL.URLByAppendingPathComponent("temp.jpg")
                        self.imageView.image = image
                        //self.buttonCapture.setImage(image, forState: .Normal)
                        if imageData.writeToURL(filePath, atomically: true) {
                            dispatch_async(dispatch_get_main_queue(), {
                                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                                let filePath = documentsURL.URLByAppendingPathComponent("temp.jpg")
                                //self.imageView.image = UIImage(contentsOfFile: String(filePath))
                                self.buttonCapture.setTitle("Try Next", forState: .Normal)
                            })
                        }
                    }
                }else{
                    print("Capturing still image error: \(error)")
                }
            })
        }
    }
    
    //MARK:- Capture devices and capture input devices
    /*
     Gives a camera device with type and position of device (back or front)
     */
    private func getCameraDeviceOfSpecificPosition(devicesWithMediaType: String, position: AVCaptureDevicePosition) -> AVCaptureDevice?{
        if let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as? [AVCaptureDevice] {
            let device = availableCameraDevices.filter({ (device) -> Bool in
                return device.position == position
            })
            if device.count > 0 {
                return device.first!
            }else {
                print("No device in given position")
            }
        }else {
            print("No camera device")
        }
        return nil
    }
    /*
     Gives capture device input for the given capture device
     AVCaptureDeviceInput provides input data coming from the device
     */
    private func getCaptureDeviceInputForCaptureDevice(captureDevice: AVCaptureDevice) -> AVCaptureDeviceInput? {
        do {
            return try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            print("Cannot get input: \(error)")
        }
        return nil
    }
    
    /*
     We must add input device to session for getting input from the device to that session
     */
    private func addInputDeviceToSession(device: AVCaptureDeviceInput, session: AVCaptureSession) -> Bool {
        if session.canAddInput(device) {
            session.addInput(device)
            return true
        }
        print("Cant add input to session")
        return !true
    }
    
    /*
     we must add video output for generating outputs
     */
    private func addCaptureVideoOutputToSession<T:AVCaptureVideoDataOutputSampleBufferDelegate>(catpureSession session: AVCaptureSession, videoOutput: AVCaptureVideoDataOutput, sampleBufferdelegateObject: T, queue: dispatch_queue_t) -> Bool{
        videoOutput.setSampleBufferDelegate(sampleBufferdelegateObject, queue: queue)
        return addCaptureOutputToSession(captureSession: session, captureOutput: videoOutput)
    }
    
    /*
     add output to session
     */
    private func addCaptureOutputToSession(captureSession session: AVCaptureSession, captureOutput output: AVCaptureOutput) -> Bool{
        if session.canAddOutput(output){
            session.addOutput(output)
            return true
        }
        return !true
    }
    
    //MARK:- input device permissions check
    /*
     check if it is authorized for accessing the device input or not
     */
    private func deviceAuthorizationCheck(deviceMediaType: String) -> Bool{
        switch AVCaptureDevice.authorizationStatusForMediaType(deviceMediaType) {
        case .Authorized:
            break
        case .Restricted, .Denied:
            print("user explicitly denied camera usage.")
        case .NotDetermined:
            //ask for permission
            AVCaptureDevice.requestAccessForMediaType(deviceMediaType, completionHandler: { (permissionGrantStatus) in
                return permissionGrantStatus
            })
        }
        return !true
    }
    
    /*
     Attach preview layer to session to display output from the camera or Video Capturing devices.
     */
    private func attachPreviewLayerToSession(session: AVCaptureSession, viewToAddLayer view: UIView, frameForPreviewLayer frame: CGRect? = nil) {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        if let frame = frame {
            previewLayer.frame = frame
        }else {
            previewLayer.frame = self.view.bounds
        }
        //        if let layers = view.layer.sublayers {
        //            for layer in layers {
        //                layer.removeFromSuperlayer()
        //            }
        //        }
        view.layer.addSublayer(previewLayer)
    }
    /*
     set quality of image/video for session
     */
    private func capturePresetForCaptureDevice(session: AVCaptureSession , currentDevice: AVCaptureDevice, isOutputStillImage: Bool ){
        let capturePreset = self.getCaptureSessionPresetForOutputMode(isOutputStillImage)
        if currentDevice.supportsAVCaptureSessionPreset(capturePreset) {
            session.sessionPreset = capturePreset
        } else {
            session.sessionPreset = AVCaptureSessionPresetLow
        }
    }
    
    /*
     Determine which quality of audio or video is to be captured
     */
    private func getCaptureSessionPresetForOutputMode(stillImage: Bool) -> String {
        return (stillImage) ? AVCaptureSessionPresetPhoto : AVCaptureSessionPresetMedium
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
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
    }
}
