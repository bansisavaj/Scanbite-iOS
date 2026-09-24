import AVFoundation
import SwiftUI

struct IngredientCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> IngredientCameraViewController {
        let controller = IngredientCameraViewController()
        controller.onImageCaptured = onImageCaptured
        return controller
    }

    func updateUIViewController(_ uiViewController: IngredientCameraViewController, context: Context) {}
}

final class IngredientCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onImageCaptured: ((UIImage) -> Void)?

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let captureButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCamera()
        configureCaptureButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        captureButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 58)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        onImageCaptured?(image)
    }

    @objc private func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    private func configureCamera() {
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(photoOutput) else { return }

        session.addInput(input)
        session.addOutput(photoOutput)

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    private func configureCaptureButton() {
        captureButton.frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        captureButton.layer.cornerRadius = 36
        captureButton.backgroundColor = .white
        captureButton.tintColor = .black
        captureButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
    }
}
