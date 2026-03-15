import SwiftUI
import Vision
import PhotosUI
@preconcurrency import AVFoundation

struct ContentView: View {
    
    @State private var scannerViewModel = BarcodeScannerViewModel()
    @State private var selectedImage: PhotosPickerItem?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            BarcodeScannerView(session: scannerViewModel.session)
                .ignoresSafeArea()
                .task {
                    await scannerViewModel.start()
                }
            
            VStack(spacing: 12) {
                
                Text(scannerViewModel.scannedCode ?? "Scan a code")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
               
                
                PhotosPicker(selection: $selectedImage, matching: .images) {
                    Label("Upload QR", systemImage: "photo")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .onChange(of: selectedImage) { _, newItem in
                    guard let newItem else { return }

                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {

                            print("Image selected")   // debug
                            await scannerViewModel.detectQRCode(from: image)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct BarcodeScannerView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) { }
    
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

@MainActor
@Observable
class BarcodeScannerViewModel {
    private(set) var isRunning = false
    private(set) var scannedCode: String?
    private(set) var error: Error?
    
    private let captureService = BarcodeScannerCaptureService()
    var session: AVCaptureSession { captureService.captureSession }
    
    func start() async {
        do {
            try await captureService.start()
            isRunning = true
            scannedStringListener()
        } catch {
            self.error = error
        }
    }
    
    private func scannedStringListener() {
        Task {
            guard let scannedStringStream = await captureService.scannedStringStream else { return }
            for await codeString in scannedStringStream {
                scannedCode = codeString
            }
        }
    }
    func detectQRCode(from image: UIImage) async {

        guard let ciImage = CIImage(image: image) else {
            print("Failed to convert image")
            return
        }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(ciImage: ciImage)

        do {
            try handler.perform([request])

            if let result = request.results?.first,
               let payload = result.payloadStringValue {

                scannedCode = payload
                print("QR detected:", payload)

            } else {
                print("No QR code found")
            }

        } catch {
            print("QR detection failed:", error)
        }
    }
}

actor BarcodeScannerCaptureService {
    nonisolated let captureSession = AVCaptureSession()
    private let outputSampleDelegate = OutputSampleDelegate()
    var scannedStringStream: AsyncStream<String>?
    
    private let videoQueue = DispatchQueue(label: "videoQueue")
    private let sessionQueue = DispatchSerialQueue(label: "sessionQueue")
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    func start() async throws {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return }
        
        scannedStringStream = outputSampleDelegate.scannedStringStream
        captureSession.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(outputSampleDelegate, queue: self.videoQueue)
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
    }
    
    private class OutputSampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let scannedStringStream: AsyncStream<String>
        private let continuation: AsyncStream<String>.Continuation
        
        override init() {
            let (stream, continuation) = AsyncStream.makeStream(of: String.self)
            self.scannedStringStream = stream
            self.continuation = continuation
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            self.detectBarcode(in: pixelBuffer)
        }
        
        private func detectBarcode(in pixelBuffer: CVPixelBuffer) {
            let request = VNDetectBarcodesRequest()
            
            /*
             
             Use the following line to restrict the type of symbologies (scannable code types)
             that the scanner will detect
             
             request.symbologies = [.qr, .ean13, .code128]
             
             Scannable symbologies are as follows
             
             1D Barcodes:
             codabar, code128, code39, code39CheckSum, code39FullASCII, code39FullASCIIChecksum, code93, code93i, i2of5, i2of5Checksum, msiPlessey, upce
             
             2D Barcodes:
             aztec, dataMatrix, microPDF417, microQR, pdf417, qr
             
             Product Codes:
             ean13, ean8, gs1DataBar, gs1DataBarExpanded, gs1DataBarLimited, itf14
             */
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            do {
                try handler.perform([request])
                if let results = request.results, let payload = results.first?.payloadStringValue {
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    continuation.yield(payload)
                }
            } catch {
                print("Barcode detection failed: \(error)")
            }
        }
    }
}

/*
 
 Uncomment this section to display SwiftUI preview
 
 #Preview {
     ContentView()
 }
 */
