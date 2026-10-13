import CoreLocation
import MapKit
import UIKit

/// Offline map crop + install demo (Android `OfflineMapDownloadFragment` + HaWoFit `HwOfflineMapsVC`).
///
/// # Flow
/// 1. MapKit map with a centered square crop frame (WGS84 — no GCJ transform needed).
/// 2. Authorize: cloud `authCode` → `setDeviceMapAuthCode`.
/// 3. Request PiMap package for the crop bounds → space check.
/// 4. `setDeviceMapRange` → download zip + MD5 → `SifliWatchfaceSDK.pushOfflineMap`.
/// 5. Optional theme: light / dark via `setDeviceMapTheme`.
final class OfflineMapDownloadViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    private let repo = BleRepository.shared
    private let locationManager = CLLocationManager()

    private let mapView = MKMapView()
    private let cropFrame = UIView()
    private let distanceLabel = UIHelpers.makeLabel("- -", style: .footnote)
    private let statusLabel = UIHelpers.makeLabel("")
    private let tipLabel = UIHelpers.makeLabel("", style: .footnote)
    private let installButton = UIHelpers.makeButton("", primary: true)
    private let cancelButton = UIHelpers.makeButton("")
    private let progress = UIProgressView(progressViewStyle: .default)
    private let phaseLabel = UIHelpers.makeLabel("", style: .footnote)
    private let logView = UITextView()

    private var busy = false
    private var mapAuthorizedLocal = false
    private var hasCentered = false

    private static let defaultLat = 39.9042
    private static let defaultLon = 116.4074
    private static let defaultSpan: CLLocationDegrees = 0.08
    /// HaWoFit / Android max crop width ≈ 49 km.
    private static let maxSpanMetres: Double = 49_000

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("offline_map")
        view.backgroundColor = .systemBackground
        statusLabel.text = L10n.tr("feature_ready")
        tipLabel.text = L10n.tr("offline_map_battery_tip")
        tipLabel.textColor = .secondaryLabel
        tipLabel.numberOfLines = 0
        distanceLabel.textAlignment = .center
        installButton.setTitle(L10n.tr("offline_map_install"), for: .normal)
        cancelButton.setTitle(L10n.tr("cancel"), for: .normal)
        installButton.addTarget(self, action: #selector(installTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        progress.progress = 0
        phaseLabel.textColor = .secondaryLabel

        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false

        cropFrame.isUserInteractionEnabled = false
        cropFrame.layer.borderColor = UIColor.systemBlue.cgColor
        cropFrame.layer.borderWidth = 2
        cropFrame.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        cropFrame.translatesAutoresizingMaskIntoConstraints = false

        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.backgroundColor = .secondarySystemBackground
        logView.layer.cornerRadius = 8

        let bottom = UIStackView(arrangedSubviews: [
            distanceLabel, tipLabel, statusLabel, phaseLabel, progress,
            installButton, cancelButton, logView
        ])
        bottom.axis = .vertical
        bottom.spacing = 8
        bottom.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mapView)
        view.addSubview(cropFrame)
        view.addSubview(bottom)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.48),

            cropFrame.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            cropFrame.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            cropFrame.widthAnchor.constraint(equalTo: mapView.widthAnchor, multiplier: 0.72),
            cropFrame.heightAnchor.constraint(equalTo: cropFrame.widthAnchor),

            bottom.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 12),
            bottom.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottom.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottom.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            logView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        requestLocationAndCenter()
        updateDistanceLabel()
    }

    // MARK: - Location

    private func requestLocationAndCenter() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            centerMap(lat: Self.defaultLat, lon: Self.defaultLon)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            if !hasCentered { centerMap(lat: Self.defaultLat, lon: Self.defaultLon) }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        if !hasCentered {
            centerMap(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !hasCentered { centerMap(lat: Self.defaultLat, lon: Self.defaultLon) }
        append(error.localizedDescription)
    }

    private func centerMap(lat: Double, lon: Double) {
        hasCentered = true
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: Self.defaultSpan, longitudeDelta: Self.defaultSpan)
        )
        mapView.setRegion(region, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateDistanceLabel()
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        updateDistanceLabel()
    }

    // MARK: - Crop

    private struct LatLngBox {
        var minLat: Double
        var minLon: Double
        var maxLat: Double
        var maxLon: Double
        var centerLat: Double { (minLat + maxLat) / 2 }
        var centerLon: Double { (minLon + maxLon) / 2 }
    }

    private func currentCropBox() -> LatLngBox? {
        view.layoutIfNeeded()
        let frameInMap = mapView.convert(cropFrame.bounds, from: cropFrame)
        guard frameInMap.width > 1, frameInMap.height > 1 else { return nil }
        let nw = mapView.convert(CGPoint(x: frameInMap.minX, y: frameInMap.minY), toCoordinateFrom: mapView)
        let se = mapView.convert(CGPoint(x: frameInMap.maxX, y: frameInMap.maxY), toCoordinateFrom: mapView)
        return LatLngBox(
            minLat: min(nw.latitude, se.latitude),
            minLon: min(nw.longitude, se.longitude),
            maxLat: max(nw.latitude, se.latitude),
            maxLon: max(nw.longitude, se.longitude)
        )
    }

    private func updateDistanceLabel() {
        guard let box = currentCropBox() else { return }
        let metres = CLLocation(latitude: box.maxLat, longitude: box.minLon)
            .distance(from: CLLocation(latitude: box.maxLat, longitude: box.maxLon))
        distanceLabel.text = String(format: "%.2f km", metres / 1000.0)
    }

    /// Shrinks the box until east–west span ≤ `maxMetres` (Android `clampBoxWidth`).
    private static func clampBoxWidth(_ box: LatLngBox, maxMetres: Double = maxSpanMetres) -> LatLngBox {
        var minLat = min(box.minLat, box.maxLat)
        var maxLat = max(box.minLat, box.maxLat)
        var minLon = min(box.minLon, box.maxLon)
        var maxLon = max(box.minLon, box.maxLon)
        let detal = 0.01 / 8.0
        var guardCount = 0
        while guardCount < 10_000 {
            guardCount += 1
            let w = CLLocation(latitude: maxLat, longitude: maxLon)
                .distance(from: CLLocation(latitude: maxLat, longitude: minLon))
            if w <= maxMetres { break }
            minLat += detal
            minLon += detal
            maxLat -= detal
            maxLon -= detal
        }
        return LatLngBox(
            minLat: min(minLat, maxLat),
            minLon: min(minLon, maxLon),
            maxLat: max(minLat, maxLat),
            maxLon: max(minLon, maxLon)
        )
    }

    // MARK: - Install

    @objc private func installTapped() {
        guard !busy else { return }
        guard repo.isConnected() else {
            statusLabel.text = L10n.tr("status_need_connect")
            append(L10n.tr("status_need_connect"))
            return
        }
        guard var box = currentCropBox() else {
            statusLabel.text = L10n.tr("offline_map_not_ready")
            return
        }
        box = Self.clampBoxWidth(box)
        busy = true
        setBusyUI(true)
        progress.progress = 0
        phaseLabel.text = L10n.tr("offline_map_phase_download")
        statusLabel.text = L10n.tr("offline_map_authorizing")
        append(L10n.tr("offline_map_authorizing"))

        ensureAuthorized { [weak self] authResult in
            guard let self = self else { return }
            switch authResult {
            case .failure(let e):
                self.finishFail(e.localizedDescription)
            case .success:
                self.repo.getOfflineMapAvailableStorageKb { storageResult in
                    let availableKb: Int
                    switch storageResult {
                    case .success(let kb): availableKb = kb
                    case .failure: availableKb = -1
                    }
                    self.repo.getDeviceInfo { infoResult in
                        switch infoResult {
                        case .failure(let e):
                            self.finishFail(e.localizedDescription)
                        case .success(let info):
                            self.requestAndPush(box: box, info: info, availableKb: availableKb)
                        }
                    }
                }
            }
        }
    }

    private func ensureAuthorized(completion: @escaping (Result<Void, Error>) -> Void) {
        if mapAuthorizedLocal {
            completion(.success(()))
            return
        }
        if let bound = repo.loadBoundDevice(), bound.mapAuthorized == true {
            mapAuthorizedLocal = true
            completion(.success(()))
            return
        }
        repo.getDeviceInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e): completion(.failure(e))
            case .success(let info):
                if info.mapAuthorized {
                    self.mapAuthorizedLocal = true
                    completion(.success(()))
                    return
                }
                let mapUuid = info.mapUuid?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !mapUuid.isEmpty else {
                    completion(.failure(SdkError(code: -1, message: L10n.tr("offline_map_no_map_uuid"))))
                    return
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let authCode = try OfflineMapApi.fetchAuthCode(mapUuid: mapUuid)
                        DispatchQueue.main.async {
                            self.repo.setDeviceMapAuthCode(uuid: mapUuid, authCode: authCode) { setResult in
                                switch setResult {
                                case .failure(let e): completion(.failure(e))
                                case .success:
                                    self.mapAuthorizedLocal = true
                                    var updated = info
                                    updated.mapAuthorized = true
                                    updated.mapUuid = mapUuid
                                    if let mac = self.repo.connectedMac() ?? info.mac {
                                        self.repo.saveBoundDevice(
                                            mac: mac,
                                            name: self.repo.connectedName(),
                                            info: updated
                                        )
                                    }
                                    completion(.success(()))
                                }
                            }
                        }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                }
            }
        }
    }

    private func requestAndPush(box: LatLngBox, info: BleDeviceInfoModel, availableKb: Int) {
        let mapUuid = info.mapUuid?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !mapUuid.isEmpty else {
            finishFail(L10n.tr("offline_map_no_map_uuid"))
            return
        }
        let productCode = (info.type?.isEmpty == false) ? (info.type ?? "unknown") : "unknown"
        statusLabel.text = L10n.tr("offline_map_requesting")
        append(L10n.tr("offline_map_requesting"))

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let pkg = try OfflineMapApi.requestOfflinePackage(
                    mapUuid: mapUuid,
                    productCode: productCode,
                    minLon: box.minLon,
                    minLat: box.minLat,
                    maxLon: box.maxLon,
                    maxLat: box.maxLat,
                    centerLat: box.centerLat,
                    centerLon: box.centerLon
                )
                DispatchQueue.main.async {
                    if let uncompressed = pkg.uncompressedSize, uncompressed > 0, availableKb > 0 {
                        let neededKb = Double(uncompressed) / 1024.0 + 16.0
                        if neededKb > Double(availableKb) {
                            self.finishFail(L10n.tr("offline_map_space_short"))
                            self.showSpaceAlert(neededKb: Int(neededKb), availableKb: availableKb)
                            return
                        }
                    }
                    self.setRangeThenPush(box: box, pkg: pkg)
                }
            } catch {
                DispatchQueue.main.async { self.finishFail(error.localizedDescription) }
            }
        }
    }

    private func setRangeThenPush(box: LatLngBox, pkg: PiMapInfo) {
        repo.setDeviceMapRange(
            centerLat: box.centerLat,
            centerLon: box.centerLon,
            maxLon: box.maxLon,
            minLon: box.minLon,
            maxLat: box.maxLat,
            minLat: box.minLat
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e):
                self.finishFail(e.localizedDescription)
            case .success:
                self.statusLabel.text = L10n.tr("offline_map_downloading")
                self.phaseLabel.text = L10n.tr("offline_map_phase_download")
                self.append(L10n.tr("offline_map_downloading"))
                self.repo.pushOfflineMap(
                    info: pkg,
                    onDownloadProgress: { [weak self] p in
                        self?.progress.progress = p * 0.5
                        self?.phaseLabel.text = L10n.tr("offline_map_phase_download")
                        self?.statusLabel.text = L10n.tr("offline_map_downloading")
                    },
                    onInstallProgress: { [weak self] pct in
                        self?.progress.progress = 0.5 + Float(pct) / 200.0
                        self?.phaseLabel.text = L10n.tr("offline_map_phase_install")
                        self?.statusLabel.text = L10n.tr("offline_map_installing")
                    },
                    completion: { [weak self] pushResult in
                        guard let self = self else { return }
                        switch pushResult {
                        case .failure(let e):
                            self.finishFail(e.localizedDescription)
                        case .success:
                            self.busy = false
                            self.setBusyUI(false)
                            self.progress.progress = 1
                            self.statusLabel.text = L10n.tr("offline_map_install_ok")
                            self.phaseLabel.text = L10n.tr("feature_success")
                            self.append(L10n.tr("offline_map_install_ok"))
                            self.showThemePicker()
                        }
                    }
                )
            }
        }
    }

    @objc private func cancelTapped() {
        repo.cancelOfflineMapTransfer()
        busy = false
        setBusyUI(false)
        statusLabel.text = L10n.tr("offline_map_cancelled")
        append(L10n.tr("offline_map_cancelled"))
    }

    private func showThemePicker() {
        let sheet = UIAlertController(
            title: L10n.tr("offline_map_select_mode"),
            message: L10n.tr("offline_map_theme_tip"),
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: L10n.tr("offline_map_light"), style: .default) { [weak self] _ in
            self?.applyTheme(light: true)
        })
        sheet.addAction(UIAlertAction(title: L10n.tr("offline_map_dark"), style: .default) { [weak self] _ in
            self?.applyTheme(light: false)
        })
        sheet.addAction(UIAlertAction(title: L10n.tr("offline_map_ok"), style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = installButton
            pop.sourceRect = installButton.bounds
        }
        present(sheet, animated: true)
    }

    private func applyTheme(light: Bool) {
        repo.setDeviceMapTheme(light: light) { [weak self] result in
            switch result {
            case .success:
                self?.statusLabel.text = L10n.tr("feature_success")
                self?.append(L10n.tr("feature_success"))
            case .failure(let e):
                self?.append(e.localizedDescription)
                self?.statusLabel.text = L10n.tr("feature_failed")
            }
        }
    }

    private func showSpaceAlert(neededKb: Int, availableKb: Int) {
        let alert = UIAlertController(
            title: L10n.tr("offline_map_space_title"),
            message: L10n.tr("offline_map_space_message", neededKb, availableKb),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("offline_map_ok"), style: .default))
        present(alert, animated: true)
    }

    private func finishFail(_ message: String) {
        busy = false
        setBusyUI(false)
        statusLabel.text = message
        append(message)
    }

    private func setBusyUI(_ busy: Bool) {
        installButton.isEnabled = !busy
        installButton.alpha = busy ? 0.7 : 1
    }

    private func append(_ line: String) {
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logView.text = (logView.text ?? "") + "\n\(stamp)  \(line)"
        let range = NSRange(location: (logView.text as NSString).length - 1, length: 1)
        logView.scrollRangeToVisible(range)
    }
}
