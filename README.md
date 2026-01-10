# SwiftUIBarcodeScannerExample

SwiftUIBarcodeScannerExample is a minimal, modern SwiftUI application that demonstrates how to scan barcodes and QR codes using AVFoundation and Vision, while embracing Swift’s latest concurrency model (Swift6.2). It updates and refactors the original example from [“Reading QR codes and barcodes with the Vision framework”]((https://www.createwithswift.com/reading-qr-codes-and-barcodes-with-the-vision-framework/)) on [CreateWithSwift.com](https://www.createwithswift.com/). You can find more about the author [Luca Palmese here](https://www.createwithswift.com/author/luca/).

While Luca’s original example provides a great starting point for Vision-based scanning, there were no existing examples that were fully compatible with **SwiftUI** and **Swift 6.2’s strict concurrency checks**, particularly around safe usage of **AVCaptureSession**. This project fills in the gaps by refactoring and modernizing the implementation so it integrates smoothly with **SwiftUI** and **Swift’s structured concurrency**.

If you want an overly dramatic retelling of how I updated [Luca Palmese's example](https://www.createwithswift.com/author/luca/), check out my article at [ARTICLE LINK HERE](#). It will be published soon on Substack/Medium (link forthcoming).

## See it in action
[video or screenshot]

## Modern Swift Highlights
- Swift 6.2 concurrency
- SwiftUI + AVFoundation + Vision
- Actors & @Observable
...

## Callouts
- Sendable requirement on detectBarcode
- @MainActor on view model redundant in Xcode 26.2
