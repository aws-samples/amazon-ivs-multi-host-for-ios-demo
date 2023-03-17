//
//  CameraModel.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 14/09/2022.
//

import AVFoundation
import UIKit
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewType = CameraPreviewController

    @Binding var isPreviewActive: Bool
    @Binding var isFrontCameraActive: Bool

    func makeUIViewController(context: Context) -> CameraPreviewController {
        return CameraPreviewController()
    }

    func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {
        if isPreviewActive {
            uiViewController.startCaptureSession()
        } else {
            uiViewController.stopCaptureSession()
        }

        if (uiViewController.activeCamera?.position == .front && !isFrontCameraActive) ||
            (uiViewController.activeCamera?.position == .back && isFrontCameraActive) {
            uiViewController.swapCamera()
        }
    }
}

class CameraPreviewController: UIViewController {
    var captureSession = AVCaptureSession()
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var activeCamera: AVCaptureDevice?
    var captureDeviceInput: AVCaptureDeviceInput?

    private var configurationInProgress: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreviewLayer()
        setupCameras()
    }

    func setupPreviewLayer() {
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720

        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.session = captureSession
        cameraPreviewLayer?.frame = CGRect(x: view.frame.width / 5,
                                           y: 0,
                                           width: 225,
                                           height: 400)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.backgroundColor = UIColor.black.cgColor
        view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }

    func setupCameras() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInDualCamera,
                .builtInTrueDepthCamera,
                .builtInWideAngleCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera
            ],
            mediaType: AVMediaType.video,
            position: .unspecified)
        frontCamera = deviceDiscoverySession.devices.first(where: { $0.position == .front })
        backCamera = deviceDiscoverySession.devices.last(where: { $0.position == .back })
        let isFrontCameraSelected = (UserDefaults.standard.value(forKey: Constants.kActiveFrontCamera) as? Bool) ?? true
        activeCamera = isFrontCameraSelected ? frontCamera : backCamera
    }

    func setupInput(_ camera: AVCaptureDevice) {
        if configurationInProgress {
            print("ℹ cameras configuration already in progress")
            return
        }

        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: camera)

            captureSession.beginConfiguration()
            configurationInProgress = true

            for input in captureSession.inputs {
                captureSession.removeInput(input)
            }

            guard captureSession.canAddInput(captureDeviceInput!) else {
                print("ℹ ❌ AVCaptureSession can't add input \(captureDeviceInput!)")
                return
            }

            captureSession.addInput(captureDeviceInput!)
            activeCamera = camera
            print("ℹ camera preview input set to \(camera)")
        } catch {
            print("ℹ ❌ Error creating AVCaptureDeviceInput with camera: \(error)")
        }
        captureSession.commitConfiguration()
        configurationInProgress = false
    }

    func swapCamera() {
        let isFrontCameraSelected = (UserDefaults.standard.value(forKey: Constants.kActiveFrontCamera) as? Bool) ?? true
        if isFrontCameraSelected {
            guard let backCamera = backCamera else {
                print("ℹ ❌ no camera available for preview")
                return
            }
            setupInput(backCamera)
        } else {
            guard let frontCamera = frontCamera else {
                print("ℹ ❌ no camera available for preview")
                return
            }
            setupInput(frontCamera)
        }
        UserDefaults.standard.set(!isFrontCameraSelected, forKey: Constants.kActiveFrontCamera)
    }

    public func startCaptureSession() {
        if captureSession.isRunning {
            print("ℹ camera preview capture session already running")
            return
        }

        if let activeCamera = activeCamera {
            setupInput(activeCamera)
        }
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }

    public func stopCaptureSession() {
        captureSession.stopRunning()
        if let input = captureDeviceInput {
            captureSession.removeInput(input)
            captureDeviceInput = nil
        }
    }
}
