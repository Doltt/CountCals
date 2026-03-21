//
//  CustomCameraPreview.swift
//  Pace
//

import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Camera Preview View

struct CustomCameraPreview: View {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void
    var onPickFromLibrary: ((UIImage) -> Void)? = nil

    @State private var cameraManager = CameraManager()
    @State private var showFlash = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var cornerBracketOpacity: CGFloat = 0.6

    var body: some View {
        ZStack {
            // Camera preview (only show if session is available)
            Group {
                if let session = cameraManager.session {
                    CameraPreviewLayer(session: session)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }
            }

            // Flash overlay for capture feedback
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // UI overlay
            VStack(spacing: 0) {
                // Top bar with cancel button
                topBar

                Spacer()

                // Center: Framing guide with hint
                framingGuide

                Spacer()

                // Bottom: Controls
                bottomControls
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("[CustomCameraPreview] onAppear - starting camera session")
            cameraManager.startSession()
            startCornerAnimation()
        }
        .onDisappear {
            print("[CustomCameraPreview] onDisappear - stopping camera session")
            cameraManager.stopSession()
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            loadSelectedPhoto(newValue)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Framing Guide

    private var framingGuide: some View {
        VStack(spacing: 16) {
            // Corner brackets with hint text
            ZStack {
                // Four corner brackets
                CornerBracketsView()
                    .opacity(cornerBracketOpacity)

                // Hint text at bottom of frame
                VStack {
                    Spacer()
                    Text(AppSettingsManager.shared.localized(.placeInFrame))
                        .font(.paceRounded(.subheadline))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                        .padding(.bottom, 20)
                }
            }
            .frame(width: 280, height: 340)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 50) {
            // Cancel button
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.paceRounded(.title2))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.3), in: Circle())
            }

            // Shutter button
            RainbowShutterButton {
                capturePhoto()
            }

            // Photo library picker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.paceRounded(.title2))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions

    private func capturePhoto() {
        // Show flash
        withAnimation(.easeOut(duration: 0.1)) {
            showFlash = true
        }

        // Capture image
        cameraManager.capturePhoto { image in
            // Hide flash
            withAnimation(.easeIn(duration: 0.15)) {
                showFlash = false
            }

            if let image {
                onCapture(image)
            }
        }
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    if let handler = onPickFromLibrary {
                        handler(image)
                    } else {
                        onCapture(image)
                    }
                }
            }
        }
    }

    private func startCornerAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            cornerBracketOpacity = 1.0
        }
    }
}

// MARK: - Corner Brackets View

struct CornerBracketsView: View {
    let cornerLength: CGFloat = 40
    let lineWidth: CGFloat = 3
    let cornerRadius: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Top-left corner
                CornerBracket(corner: .topLeft, length: cornerLength, lineWidth: lineWidth, radius: cornerRadius)
                    .position(x: cornerLength / 2, y: cornerLength / 2)

                // Top-right corner
                CornerBracket(corner: .topRight, length: cornerLength, lineWidth: lineWidth, radius: cornerRadius)
                    .position(x: width - cornerLength / 2, y: cornerLength / 2)

                // Bottom-left corner
                CornerBracket(corner: .bottomLeft, length: cornerLength, lineWidth: lineWidth, radius: cornerRadius)
                    .position(x: cornerLength / 2, y: height - cornerLength / 2)

                // Bottom-right corner
                CornerBracket(corner: .bottomRight, length: cornerLength, lineWidth: lineWidth, radius: cornerRadius)
                    .position(x: width - cornerLength / 2, y: height - cornerLength / 2)
            }
        }
    }
}

struct CornerBracket: View {
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    let corner: Corner
    let length: CGFloat
    let lineWidth: CGFloat
    let radius: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()

            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: radius))
                path.addQuadCurve(to: CGPoint(x: radius, y: 0), control: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))

            case .topRight:
                path.move(to: CGPoint(x: length - length, y: 0))
                path.addLine(to: CGPoint(x: length - radius, y: 0))
                path.addQuadCurve(to: CGPoint(x: length, y: radius), control: CGPoint(x: length, y: 0))
                path.addLine(to: CGPoint(x: length, y: length))

            case .bottomLeft:
                path.move(to: CGPoint(x: length, y: length))
                path.addLine(to: CGPoint(x: radius, y: length))
                path.addQuadCurve(to: CGPoint(x: 0, y: length - radius), control: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: 0))

            case .bottomRight:
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: length - radius, y: length))
                path.addQuadCurve(to: CGPoint(x: length, y: length - radius), control: CGPoint(x: length, y: length))
                path.addLine(to: CGPoint(x: length, y: 0))
            }

            context.stroke(path, with: .color(.white), lineWidth: lineWidth)
        }
        .frame(width: length, height: length)
    }
}

// MARK: - Rainbow Shutter Button

struct RainbowShutterButton: View {
    let action: () -> Void

    @State private var isPressed = false
    @State private var rotationAngle: Double = 0

    // Rainbow gradient colors
    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red
    ]

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                // Outer rainbow ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: rainbowColors,
                            center: .center,
                            startAngle: .degrees(rotationAngle),
                            endAngle: .degrees(rotationAngle + 360)
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 76, height: 76)

                // Inner white fill
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            // Slow rotation animation for the rainbow ring
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Spinning Rainbow Ring (for processing state)

struct SpinningRainbowRing: View {
    @State private var rotationAngle: Double = 0

    private let rainbowColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red
    ]

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
                .frame(width: 64, height: 64)

            // Spinning rainbow ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: rainbowColors,
                        center: .center,
                        startAngle: .degrees(rotationAngle),
                        endAngle: .degrees(rotationAngle + 360)
                    ),
                    lineWidth: 4
                )
                .frame(width: 76, height: 76)
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Camera Preview Layer (UIKit Bridge)

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

final class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            previewLayer.session = session
        }
    }
    
    private let previewLayer = AVCaptureVideoPreviewLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - Camera Manager

@Observable
final class CameraManager: NSObject {
    private(set) var session: AVCaptureSession?

    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    /// Serial queue for all AVCaptureSession configuration and start/stop/capture to avoid undefined reuse / races.
    private let sessionQueue = DispatchQueue(label: "com.tree.countCals.camera.session")

    override init() {
        super.init()
        print("[CameraManager] Initializing...")
        sessionQueue.async { [weak self] in
            self?.configureSessionOnQueue()
        }
    }

    private func configureSessionOnQueue() {
        print("[CameraManager] Setting up session...")
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("[CameraManager] ❌ Camera unavailable - no wide angle camera found")
            return
        }
        print("[CameraManager] Found camera: \(camera.localizedName)")

        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            print("[CameraManager] ❌ Failed to create input - permission denied or simulator")
            return
        }

        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            print("[CameraManager] ✅ Input added to session")
        } else {
            print("[CameraManager] ❌ Cannot add input to session")
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            print("[CameraManager] ✅ Photo output added to session")
        } else {
            print("[CameraManager] ❌ Cannot add photo output to session")
        }

        captureSession.commitConfiguration()

        // Start on the same serial queue before exposing `session` so onAppear never races a nil session.
        if !captureSession.isRunning {
            captureSession.startRunning()
            print("[CameraManager] ✅ Session running after configuration")
        }

        DispatchQueue.main.async { [weak self] in
            self?.session = captureSession
            print("[CameraManager] ✅ Session configured successfully")
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, let session = self.session else {
                print("[CameraManager] ❌ Cannot start - session is nil")
                return
            }
            guard !session.isRunning else {
                print("[CameraManager] Session already running")
                return
            }
            print("[CameraManager] Starting session...")
            session.startRunning()
            print("[CameraManager] ✅ Session started")
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, let session = self.session else {
                print("[CameraManager] ❌ Cannot stop - session is nil")
                return
            }
            guard session.isRunning else {
                print("[CameraManager] Session already stopped")
                return
            }
            print("[CameraManager] Stopping session...")
            session.stopRunning()
            print("[CameraManager] ✅ Session stopped")
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let session = self.session, session.isRunning else {
                print("[CameraManager] Cannot capture: session not running")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self.captureCompletion = completion
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("[CameraManager] Photo capture error: \(error)")
            DispatchQueue.main.async {
                let done = self.captureCompletion
                self.captureCompletion = nil
                done?(nil)
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("[CameraManager] Failed to create image from photo data")
            DispatchQueue.main.async {
                let done = self.captureCompletion
                self.captureCompletion = nil
                done?(nil)
            }
            return
        }

        DispatchQueue.main.async {
            let done = self.captureCompletion
            self.captureCompletion = nil
            done?(image)
        }
    }
}

// MARK: - Preview

#Preview {
    CustomCameraPreview(
        onCapture: { _ in },
        onCancel: { }
    )
}
