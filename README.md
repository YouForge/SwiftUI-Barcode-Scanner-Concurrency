# SwiftUIBarcodeScannerExample

SwiftUIBarcodeScannerExample is a minimal, modern **SwiftUI** application that demonstrates how to scan b**arcodes and QR codes** using **AVFoundation** and **Vision**, while embracing the **Swift 6.2 concurrency model**. It updates and refactors the original example from [“Reading QR codes and barcodes with the Vision framework”](https://www.createwithswift.com/reading-qr-codes-and-barcodes-with-the-vision-framework/) on [CreateWithSwift.com](https://www.createwithswift.com/). You can find more about the author [Luca Palmese here](https://www.createwithswift.com/author/luca/).

While the original example provides a great starting point for Vision-based scanning, there were no existing examples fully compatible with **SwiftUI** and the **Swift 6.2 strict concurrency checks**, particularly around safe usage of **AVCaptureSession**. This project fills in the gaps by refactoring and modernizing the implementation for smooth integration with **SwiftUI** and **structured concurrency**.

If you want an overly dramatic retelling of how I updated the original example, check out my article at [ARTICLE LINK HERE](#). It will be published soon on Substack/Medium (link forthcoming).

## See it in action

https://github.com/user-attachments/assets/987f05ab-560a-4853-9da4-3fd27fc92d7b

SwiftUIBarcodeScannerExample scans barcodes and QR codes effortless. Supports a variety of formats and presents real-time results instantly, all utilizing modern Swift concepts and technologies.

## Modern Swift Highlights

### SwiftUI-First

The **SwiftUIBarcodeScannerExample** utilizes a SwiftUI first approach. It wraps the `UIKit PreviewView` returned from the `AVFoundation` libraries within a `UIViewRepresentable` named `BarcodeScannerView` rather than a `UIViewControllerRepresentable` so that other SwiftUI components can be added over top the view.
```swift

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

### Swift 6.2 Concurrency

The **SwiftUIBarcodeScannerExample** relies on modern the modern Swift concurrency model over the use of closures or `DispatchQueue()`. The example issolates all camera fucntionality withion a thread safe `actor` that implemnents it's own `unownedExecutor` to ensure that the setup of the `AVCaptureSession` and the `AVCaptureVideoDataOutputSampleBufferDelegate` runs on the same thead.

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

This was done to provide an example that is as close to a modern real world iOS project as possible.

### AsyncStream & Continuation

The passing of values between the `actor` and the `ViewModel` is achieved by the use of `AsyncStream` and not an `AsyncPublisher`.

```swift

@MainActor
@Observable
class BarcodeScannerViewModel {
    // ViewModel properties
    
    private func scannedStringListener() {
        Task {
            // Handle elements within stream of scanned codes
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

## Callouts
- No sendable requirement on the `AVCaptureVideoDataOutputSampleBufferDelegate`. The `OutputSampleDelegate` and the subsequent `AVCaptureVideoDataOutputSampleBufferDelegate` are not marked with the `@unchecked Sendable` or `Sendable` properties as this isn't a requirment in **Xcode 26.2 (17C52)**. It could be argued that this would make the example more readable, but it was decided that it would also make it more complicated and was therefore omitted.
- As of **Xcode 26.2 (17C52)**, the **Default Actor Isolation** is the **MainActor** and no longer **nonisolated**. This makes the `@MainActor` property above the `BarcodeScannerViewModel` class unnessecary. The property was left in the example for readability and to future proof against the possibility that this desicion is reverted in future versions of Xcode. 
- Running the **SwiftUIBarcodeScannerExample** requires a device and **does not support** running on a simulator.

## Resource Links
