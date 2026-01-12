# SwiftUIBarcodeScannerExample

SwiftUIBarcodeScannerExample is a minimal, modern **SwiftUI** application that demonstrates how to scan b**arcodes and QR codes** using **AVFoundation** and **Vision**, while embracing the **Swift 6.2 concurrency model**. It updates and refactors the original example from [“Reading QR codes and barcodes with the Vision framework”](https://www.createwithswift.com/reading-qr-codes-and-barcodes-with-the-vision-framework/) on [CreateWithSwift.com](https://www.createwithswift.com/). You can find more about the author [Luca Palmese here](https://www.createwithswift.com/author/luca/).

While the original example provides a great starting point for Vision-based scanning, there were no existing examples fully compatible with **SwiftUI** and the **Swift 6.2 strict concurrency checks**, particularly around safe usage of **AVCaptureSession**. This project fills in the gaps by refactoring and modernizing the implementation for smooth integration with **SwiftUI** and **structured concurrency**.

If you want an overly dramatic retelling of how I updated the original example, check out my article at [ARTICLE LINK HERE](#). It will be published soon on Substack/Medium (link forthcoming).

## See it in action

https://github.com/user-attachments/assets/5a16f0ed-bc56-41e2-9b65-67fb9ca4f59e

SwiftUIBarcodeScannerExample scans barcodes and QR codes effortless. Supports a variety of formats and presents real-time results instantly, all utilizing modern Swift concepts and technologies.

## Modern Swift Highlights
- **SwiftUI-first**: The _SwiftUIBarcodeScannerExample_ utilizes a SwiftUI first approach. It wraps the `UIKit PreviewView` returned from the `AVFoundation` libraries within a `UIViewRepresentable` named `BarcodeScannerView` rather than a `UIViewControllerRepresentable` so that other SwiftUI components can be added over top the view. ```swift

var body: some View {
    ZStack(alignment: .bottom) {
        BarcodeScannerView(session: scannerViewModel.session)
            .ignoresSafeArea()
            .task {
                await scannerViewModel.start()
            }

        // Aditional component on top of BarcodeScannerView
        Text(scannerViewModel.scannedCode ?? "Scan a code")
    }
}

struct BarcodeScannerView: UIViewRepresentable {    
    func makeUIView(context: Context) -> PreviewView {
        // Create the AVCaptureVideoPreviewLayer here
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) { }
}

```
This maximizes reusability when modifying the _SwiftUIBarcodeScannerExample_ or incorporating the example into your own project.
- Swift 6.2 concurrency:
- View + ViewModel + Actor Structure:
- Actors & Private Delegate Class:
- AsyncStream & Continuation:
...

## Callouts
- Sendable requirement on detectBarcode
- @MainActor on view model redundant in Xcode 26.2
