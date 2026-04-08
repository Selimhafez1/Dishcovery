import AVFoundation
import Vision
import Foundation
import UIKit
import CoreLocation

// MARK: - Review Model
struct PlaceReview: Identifiable {
    let id = UUID()
    let authorName: String
    let rating: Double
    let text: String
}

class CameraViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var detectedText: String = "Looking for text..."
    @Published var detectedRestaurantName: String = ""
    @Published var rawDetectedRestaurantName: String = ""
    @Published var reviews: [PlaceReview] = []
    @Published var placeID: String = ""

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.queue")

    // MARK: - Location
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override init() {
        super.init()
        configureSession()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    // MARK: - Camera Setup
    func startSession() {
        queue.async {
            self.session.startRunning()
        }
    }

    func stopSession() {
        queue.async {
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }

        session.addInput(videoInput)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    private func handleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let recognizedStrings = observations.compactMap {
                $0.topCandidates(1).first?.string
            }

            DispatchQueue.main.async {
                self.detectedText = recognizedStrings.joined(separator: "\n")
            }
        }

        request.recognitionLevel = .fast
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    // MARK: - Vision API
    func sendImageToVisionAPI(_ image: UIImage) {
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            return
        }

        let requestPayload: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "LOGO_DETECTION", "maxResults": 3]
                    ]
                ]
            ]
        ]

        makeVisionRequest(requestPayload, originalImage: image, isLogoStep: true)
    }

    private func makeVisionRequest(_ payload: [String: Any], originalImage: UIImage, isLogoStep: Bool) {
        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyBNoGEGIXGFg_7jNlcdul9yTTWk2j_bbxY")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }

            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

            if isLogoStep,
               let responses = json?["responses"] as? [[String: Any]],
               let logos = responses.first?["logoAnnotations"] as? [[String: Any]],
               let firstLogo = logos.first,
               let description = firstLogo["description"] as? String {

                DispatchQueue.main.async {
                    self.rawDetectedRestaurantName = description
                    self.detectedText = "Detected Logo: \(description)"
                    self.fetchPlaceDetails(for: description)
                }

            } else if isLogoStep {
                self.runTextDetectionViaVision(image: originalImage)

            } else {
                if let responses = json?["responses"] as? [[String: Any]],
                   let textAnnotations = responses.first?["textAnnotations"] as? [[String: Any]],
                   let fullText = textAnnotations.first?["description"] as? String {

                    let bestGuess = fullText.components(separatedBy: "\n").first ?? fullText

                    DispatchQueue.main.async {
                        self.rawDetectedRestaurantName = bestGuess
                        self.detectedText = "Detected via OCR: \(bestGuess)"
                        self.fetchPlaceDetails(for: bestGuess)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.detectedText = "Could not recognize the restaurant."
                    }
                }
            }
        }.resume()
    }

    func runTextDetectionViaVision(image: UIImage) {
        let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? ""

        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [["type": "TEXT_DETECTION"]]
                ]
            ]
        ]

        makeVisionRequest(requestBody, originalImage: image, isLogoStep: false)
    }

    // MARK: - Distance
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180

        let a =
            sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }


    // MARK: - Places API
    func fetchPlaceDetails(for placeName: String) {
        guard let location = currentLocation else { return }

        let apiKey = "AIzaSyCZK0O8qcnIYKhUv4Ij21BMmQAfGgwz_e4"
        let encodedName = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeName
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude

        let urlStr = """
        https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=\(encodedName)&inputtype=textquery&fields=name,rating,formatted_address,geometry,place_id&locationbias=circle:3000@\(lat),\(lng)&language=en&key=\(apiKey)
        """

        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            DispatchQueue.main.async {
                if let candidates = json["candidates"] as? [[String: Any]],
                   let place = candidates.first,
                   let geometry = place["geometry"] as? [String: Any],
                   let loc = geometry["location"] as? [String: Any],
                   let placeLat = loc["lat"] as? Double,
                   let placeLng = loc["lng"] as? Double {

                    let distance = self.haversineDistance(lat1: lat, lon1: lng, lat2: placeLat, lon2: placeLng)

                    if distance <= 3 {
                        let name = place["name"] as? String ?? ""
                        let address = place["formatted_address"] as? String ?? ""
                        let rating = place["rating"] as? Double ?? 0.0
                        let placeID = place["place_id"] as? String ?? ""

                        self.detectedRestaurantName = name
                        self.placeID = placeID
                        print("Detected restaurant name for menu search: \(name)")
                        self.detectedText = "📍 \(name)\n⭐️ \(rating)\n🏠 \(address)"

                        if !placeID.isEmpty {
                            self.fetchReviews(placeID: placeID)
                        }

                    } else {
                        self.detectedText = "No nearby restaurant found."
                        self.detectedRestaurantName = ""
                        self.reviews = []
                    }
                } else {
                    self.detectedText = "No nearby restaurant found."
                    self.detectedRestaurantName = ""
                    self.reviews = []
                }
            }
        }.resume()
    }

    // MARK: - Reviews
    func fetchReviews(placeID: String) {
        let apiKey = "AIzaSyCZK0O8qcnIYKhUv4Ij21BMmQAfGgwz_e4"

        let urlStr = """
        https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeID)&fields=reviews&language=en&key=\(apiKey)
        """

        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let reviewsArray = result["reviews"] as? [[String: Any]] else {
                return
            }

            let parsed = reviewsArray.map {
                PlaceReview(
                    authorName: $0["author_name"] as? String ?? "Anonymous",
                    rating: $0["rating"] as? Double ?? 0.0,
                    text: $0["text"] as? String ?? ""
                )
            }

            DispatchQueue.main.async {
                self.reviews = parsed
            }
        }.resume()
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handleBuffer(sampleBuffer)
    }
}
