![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-orange?logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-26.2-blue?logo=apple&logoColor=white)
![AVFoundation](https://img.shields.io/badge/AVFoundation-✓-green)

# SwiftUIBarcodeScannerExample – QR & Barcode Scanner in SwiftUI

SwiftUIBarcodeScannerExample is a minimal, modern **SwiftUI** example app that demonstrates how to scan **QR codes and barcodes** using **AVFoundation** and **Vision**, while embracing the **Swift 6.2 concurrency model**. It updates and refactors the original example from [“Reading QR codes and barcodes with the Vision framework”](https://www.createwithswift.com/reading-qr-codes-and-barcodes-with-the-vision-framework/) on [CreateWithSwift.com](https://www.createwithswift.com/). You can find more about the author [Luca Palmese here](https://www.createwithswift.com/author/luca/).

While the original example provides a great starting point for Vision-based scanning, there were no existing examples fully compatible with **SwiftUI** and the **Swift 6.2 strict concurrency checks**, particularly around the safe usage of **AVCaptureSession**. This project fills in the gaps by refactoring and modernizing the implementation for smooth integration with **SwiftUI** and **structured concurrency**.

If you want an overly dramatic retelling of how I updated the original example, check out my article at [ARTICLE LINK HERE](#). It will be published soon on Substack/Medium (link forthcoming).

## See SwiftUI Barcode & QR Code Scanner in Action

https://github.com/user-attachments/assets/987f05ab-560a-4853-9da4-3fd27fc92d7b

SwiftUIBarcodeScannerExample scans barcodes and QR codes effortlessly. It supports a variety of formats and presents real-time results instantly, all while utilizing modern SwiftUI and Swift concurrency concepts.

## Modern Swift Highlights

### SwiftUI-First QR/Barcode Scanner View

The **SwiftUIBarcodeScannerExample** utilizes a SwiftUI-first approach. It wraps a UIKit `PreviewView` backed by `AVCaptureVideoPreviewLayer` within a `UIViewRepresentable` named `BarcodeScannerView` rather than a `UIViewControllerRepresentable` so that other SwiftUI components can be added on top of the view.
```swift

var body: some View {
    ZStack(alignment: .bottom) {
        BarcodeScannerView(session: scannerViewModel.session)
            .ignoresSafeArea()
            .task {
                await scannerViewModel.start()
            }

        // Additional component on top of BarcodeScannerView
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

### Swift 6.2 Concurrency

The **SwiftUIBarcodeScannerExample** relies on the modern Swift concurrency model rather than manually coordinating work with closures or `DispatchQueue`. The example isolates all camera functionality within a thread-safe `actor` that implements its own `unownedExecutor` to ensure that the setup of the `AVCaptureSession` and the `AVCaptureVideoDataOutputSampleBufferDelegate` runs on the same thread.

```swift

actor BarcodeScannerCaptureService {
    private let sessionQueue = DispatchSerialQueue(label: "sessionQueue")
    // Define other actor properties

    // Ensures execution always happens on the sessionQueue
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    func start() async throws { /*Setup AVCaptureSession*/ }
    
    private class OutputSampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) { /*Scan codes*/ }
    }
}

```


### View + ViewModel + Actor Structure

The **SwiftUIBarcodeScannerExample** project utilizes the popular **View + ViewModel + Actor(Service/Manager) Structure** that has become so common within the industry.

```swift

struct ContentView: View { /* View */ }

@MainActor
@Observable
class BarcodeScannerViewModel { /* ViewModel */ }

actor BarcodeScannerCaptureService { /* Actor(Service/Manager) */ }

```
This was done to provide an example that is as close to a modern real-world iOS project as possible.

### AsyncStream & Continuation

The passing of values between the `actor` and the `ViewModel` is achieved by the use of `AsyncStream` and not an `AsyncPublisher` which allows barcode results to flow safely across concurrency boundaries.

```swift

@MainActor
@Observable
class BarcodeScannerViewModel {
    // ViewModel properties
    
    private func scannedStringListener() {
        Task {
            // Handle elements within the stream of scanned codes
            for await codeString in scannedStringStream {
                scannedCode = codeString
            }
        }
    }
}

actor BarcodeScannerCaptureService {
    var scannedStringStream: AsyncStream<String>?
    // Other actor properties

    func start() async throws {
        // Assign the actor stream to the delegate classes
        scannedStringStream = outputSampleDelegate.scannedStringStream
        // Continue AVCaptureSession setup
    }
    
    private class OutputSampleDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let scannedStringStream: AsyncStream<String>
        private let continuation: AsyncStream<String>.Continuation

        // Initialize OutputSampleDelegate class
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Add scanned code element to the stream
            continuation.yield("scannedCode")
        }
    }   
}

```
Under the stricter Swift 6.2 / Xcode 26.2 concurrency model, `AsyncPublisher` generates compile-time errors and therefore Apple recommends using `AsyncStream`.

## Callouts
- No `Sendable` requirement on the `AVCaptureVideoDataOutputSampleBufferDelegate`. The `OutputSampleDelegate` and the subsequent `AVCaptureVideoDataOutputSampleBufferDelegate` are not marked with the `@unchecked Sendable` or `Sendable` properties as this isn't a requirement in **Xcode 26.2 (17C52)**. It could be argued that this would make the example more readable or easier to follow, but it was decided that it would increase complexity and was therefore omitted.
- As of **Xcode 26.2 (17C52)**, the **Default Actor Isolation** is the **MainActor** and no longer **nonisolated**. This makes the `@MainActor` property above the `BarcodeScannerViewModel` class unnecessary. The property was left in the example for readability and to future-proof against the possibility that this decision is reverted in future versions of Xcode. 
- Running the **SwiftUIBarcodeScannerExample** requires a device and **does not support** running on a simulator.

## Resource Links
- [A Step-by-step article on creating **SwiftUIBarcodeScannerExample**](#)
- [Original Swift forums post](https://forums.swift.org/t/safely-use-avcapturesession-swift-6-2-concurrency/83622)
- [Original CreateWithSwift QR & Barcode Scanner article](https://www.createwithswift.com/reading-qr-codes-and-barcodes-with-the-vision-framework/) by [Luca Palmese](https://www.createwithswift.com/author/luca/)
- [`AsyncStream` and `AsyncPublisher` explanation](https://forums.swift.org/t/is-it-fair-to-declare-combines-anypublisher-as-unchecked-sendable-as-long-as-output-error-types-are-sendable/76343/5)
- [`AsyncStream` Apple documentation](https://developer.apple.com/documentation/swift/asyncstream)
