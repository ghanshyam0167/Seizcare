//
//  MapViewController.swift
//  Seizcare
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    private let mapView = MKMapView()
    private let locationManager = LocationManager.shared
    private var isFirstUpdate = true
    
    // An optional event coordinate to show a specific location instead of current tracking
    var coordinateToShow: CLLocationCoordinate2D?
    var eventTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let coordinate = coordinateToShow {
            showSpecificLocation(coordinate: coordinate, title: eventTitle)
        } else {
            startTrackingUser()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if coordinateToShow == nil {
            locationManager.stopUpdatingLocation()
        }
    }
    
    private func setupUI() {
        title = coordinateToShow != nil ? "Seizure Location" : "Live Location"
        view.backgroundColor = .systemBackground
        
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = closeButton
    }
    
    private func startTrackingUser() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        locationManager.requestAuthorization()
        locationManager.startUpdatingLocation()
        
        // Setup observer for location updates
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdate), name: NSNotification.Name("LocationUpdated"), object: nil)
    }
    
    private func showSpecificLocation(coordinate: CLLocationCoordinate2D, title: String?) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title ?? "Event Location"
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    @objc private func locationDidUpdate() {
        guard let location = locationManager.lastLocation, isFirstUpdate else { return }
        isFirstUpdate = false
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}
