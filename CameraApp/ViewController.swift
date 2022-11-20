//
//  ViewController.swift
//  CameraApp
//
//  Created by John Paul Otim on 13.11.22.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    enum C {
        static let rotateIconSystemName = "arrow.triangle.2.circlepath.camera"
        static let boltSystemName = "bolt"
        static let boltFillSystemName = "bolt.fill"
    }
    
    //Capture Session
    var session: AVCaptureSession?
    // Phot Output
    var output: AVCapturePhotoOutput?
    // Video Previw
    let previewLayer = AVCaptureVideoPreviewLayer()
    // Flag that determines if the front or back camera should be shown
    var showBackCamera = true
    
    // Shutter button
    private let shutterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    private let rotateCameraButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        button.setBackgroundImage(UIImage(systemName: C.rotateIconSystemName ), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private let flashButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 30))
        button.setBackgroundImage(UIImage(systemName: C.boltSystemName ), for: .normal)
        button.tintColor = .white
        return button
    }()
}

// Lifecycle
extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set background color to black
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        view.addSubview(rotateCameraButton)
        view.addSubview(flashButton)
        // Ask for camera permissions
        checkCameraPermissions()
        
        shutterButton.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
        
        rotateCameraButton.addTarget(self, action: #selector(didRotateCamera), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutterButton.center = CGPoint(x: view.bounds.width/2,
                                       y: view.bounds.height - 100)
        rotateCameraButton.center = CGPoint(x: shutterButton.center.x + 100, y: view.bounds.height - 100)
        flashButton.center = CGPoint(x: shutterButton.center.x - 100, y: view.bounds.height - 100)
    }
    
}

// MARK:- Private
extension ViewController {
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .notDetermined:
            // Request
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    print("Access denied")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.setupCamera()
                }
                
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            // Setup Camera
            setupCamera()
        @unknown default:
            break
        }
    }
    
    private func setupCamera(showBackCamera: Bool = true) {
        let session = AVCaptureSession()
        if let device = showBackCamera ? AVCaptureDevice.default(for: .video) : AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                } else {
                    print("Could not add input")
                }
                let _output = AVCapturePhotoOutput()
                if session.canAddOutput(_output) {
                    session.addOutput(_output)
                    self.output = _output
                } else {
                    print("Could not add output")
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                DispatchQueue.global().async {
                    session.startRunning()
                }
                self.session = session
            } catch {
                print(error)
            }
        }
    }
    
    @objc private func didTapTakePhoto() {
        output?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    @objc private func didRotateCamera() {
        session?.stopRunning()
        showBackCamera = !showBackCamera
        setupCamera(showBackCamera: showBackCamera)
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        
        let image = UIImage(data: data)
        
        session?.stopRunning()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
        
        // Remove preview of take image and start running after wards
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self, weak imageView] in
            imageView?.removeFromSuperview()
            DispatchQueue.global().async {
                self?.session?.startRunning()
            }
        }
    }
}

