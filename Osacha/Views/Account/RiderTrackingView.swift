//
//  RiderTrackingView.swift
//  Osacha
//
//  A delivery's rider on the map: the road from the café to the customer's
//  door, and the rider moving along it while the order is on its way. The
//  rider is simulated, like the order stages: their place on the road comes
//  from how far through the ride the order should be.
//

import SwiftUI
import MapKit

struct RiderTrackingView: View {
    let order: PastOrder

    @EnvironmentObject private var session: AppSession
    @Environment(\.openURL) private var openURL

    /// The road the rider takes, café first. A straight line until the real
    /// route comes back, or if it never does.
    @State private var route: [CLLocationCoordinate2D] = []

    var body: some View {
        VStack(spacing: 0) {
            // Ticks every couple of seconds so the rider moves smoothly
            // rather than jumping once per session clock tick.
            TimelineView(.periodic(from: .now, by: 2)) { context in
                RiderMap(route: route, rider: riderPosition(at: context.date), riderVisible: hasLeft(at: context.date))
                    .frame(height: 260)
                    .overlay(alignment: .topLeading) {
                        statusBadge(at: context.date)
                            .padding(12)
                    }
            }

            riderCard
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .task { await loadRoute() }
    }

    // MARK: - Where the rider is

    private var leaves: Date? {
        order.placedDate?.addingTimeInterval(PastOrder.preparingDuration)
    }

    private func hasLeft(at date: Date) -> Bool {
        guard let leaves else { return false }
        return date >= leaves
    }

    /// How far along the ride the rider is, from 0 at the café to 1 at the door.
    private func progress(at date: Date) -> Double {
        guard let leaves, let arrives = order.readyDate, arrives > leaves else { return 1 }
        return min(1, max(0, date.timeIntervalSince(leaves) / arrives.timeIntervalSince(leaves)))
    }

    private func riderPosition(at date: Date) -> CLLocationCoordinate2D {
        Self.point(along: route, at: progress(at: date)) ?? Cafe.coordinate
    }

    /// The point a fraction of the way along a path, measured by distance.
    private static func point(along path: [CLLocationCoordinate2D], at fraction: Double) -> CLLocationCoordinate2D? {
        guard let first = path.first else { return nil }
        let points = path.map(MKMapPoint.init)
        let legs = zip(points, points.dropFirst()).map { $0.distance(to: $1) }
        var remaining = legs.reduce(0, +) * fraction
        for (index, leg) in legs.enumerated() {
            if remaining <= leg, leg > 0 {
                let t = remaining / leg
                let a = points[index], b = points[index + 1]
                return MKMapPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t).coordinate
            }
            remaining -= leg
        }
        return path.last ?? first
    }

    private func distanceLeft(at date: Date) -> Double {
        guard route.count > 1 else { return 0 }
        let points = route.map(MKMapPoint.init)
        let total = zip(points, points.dropFirst()).map { $0.distance(to: $1) }.reduce(0, +)
        return total * (1 - progress(at: date))
    }

    // MARK: - Pieces

    private func statusBadge(at date: Date) -> some View {
        let text: String
        if !hasLeft(at: date) {
            text = localized("Rider is waiting for your order")
        } else if progress(at: date) < 1 {
            text = String(format: localized("%@ km away"), String(format: "%.1f", distanceLeft(at: date) / 1000))
        } else {
            text = localized("Arrived")
        }
        return Label(text, systemImage: "bicycle")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.matchaDarkGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.matchaCardCream))
    }

    private var riderCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.matchaGreen)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.matchaSage))

            VStack(alignment: .leading, spacing: 2) {
                Text(Rider.name)
                    .font(.subheadline.weight(.semibold))
                Text(Rider.vehicle)
                    .font(.caption)
                    .opacity(0.7)
                Text(String(format: localized("Arrives about %@"), order.readyDate.map(AppDate.time) ?? order.readyAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.matchaGreen)
            }
            .foregroundStyle(Color.matchaDarkGreen)

            Spacer()

            Button {
                let digits = Rider.phone.filter { $0.isNumber || $0 == "+" }
                if let url = URL(string: "tel:\(digits)") { openURL(url) }
            } label: {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.matchaGreen))
            }
            .accessibilityLabel("Call rider")
        }
        .padding(14)
        .background(Color.matchaCardCream)
    }

    // MARK: - The road

    private func loadRoute() async {
        let destination = await Self.destination(for: order.deliveryAddress ?? session.addresses.first?.oneLine)
        route = [Cafe.coordinate, destination]

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: Cafe.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        if let path = try? await MKDirections(request: request).calculate().routes.first?.polyline {
            var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: path.pointCount)
            path.getCoordinates(&coordinates, range: NSRange(location: 0, length: path.pointCount))
            if coordinates.count > 1 { route = coordinates }
        }
    }

    /// Where the address is, or a spot a short ride from the café when it
    /// can't be found.
    private static func destination(for address: String?) async -> CLLocationCoordinate2D {
        let fallback = CLLocationCoordinate2D(latitude: Cafe.coordinate.latitude + 0.012,
                                              longitude: Cafe.coordinate.longitude + 0.016)
        guard let address, !address.isEmpty else { return fallback }
        let placemarks = try? await CLGeocoder().geocodeAddressString(address + ", Philippines")
        guard let found = placemarks?.first?.location?.coordinate else { return fallback }
        // An address the geocoder places far away was misread; a rider
        // wouldn't be crossing the country.
        let distance = MKMapPoint(found).distance(to: MKMapPoint(Cafe.coordinate))
        return distance < 40_000 ? found : fallback
    }
}

/// The map itself. MapKit's own view, since SwiftUI's map can't draw a route
/// on iOS 16.
private struct RiderMap: UIViewRepresentable {
    let route: [CLLocationCoordinate2D]
    let rider: CLLocationCoordinate2D
    let riderVisible: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.drawnRoute.count != route.count || coordinator.drawnRoute.last?.latitude != route.last?.latitude {
            coordinator.drawnRoute = route
            map.removeOverlays(map.overlays)
            map.removeAnnotations(map.annotations.filter { ($0 as? Stop)?.kind != .rider })
            guard let start = route.first, let end = route.last else { return }
            let line = MKPolyline(coordinates: route, count: route.count)
            map.addOverlay(line)
            map.addAnnotations([Stop(kind: .cafe, at: start), Stop(kind: .home, at: end)])
            map.setVisibleMapRect(line.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 40, right: 40),
                                  animated: false)
        }

        if riderVisible {
            if let existing = coordinator.rider {
                UIView.animate(withDuration: 1.8, delay: 0, options: .curveLinear) {
                    existing.coordinate = rider
                }
            } else {
                let marker = Stop(kind: .rider, at: rider)
                coordinator.rider = marker
                map.addAnnotation(marker)
            }
        } else if let existing = coordinator.rider {
            map.removeAnnotation(existing)
            coordinator.rider = nil
        }
    }

    final class Stop: NSObject, MKAnnotation {
        enum Kind { case cafe, home, rider }
        let kind: Kind
        @objc dynamic var coordinate: CLLocationCoordinate2D

        init(kind: Kind, at coordinate: CLLocationCoordinate2D) {
            self.kind = kind
            self.coordinate = coordinate
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var drawnRoute: [CLLocationCoordinate2D] = []
        var rider: Stop?

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.matchaGreen)
            renderer.lineWidth = 5
            renderer.lineCap = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let stop = annotation as? Stop else { return nil }
            switch stop.kind {
            case .cafe, .home:
                let view = MKMarkerAnnotationView(annotation: stop, reuseIdentifier: nil)
                view.glyphImage = UIImage(systemName: stop.kind == .cafe ? "cup.and.saucer.fill" : "house.fill")
                view.markerTintColor = UIColor(stop.kind == .cafe ? Color.matchaPinkDeep : Color.matchaDarkGreen)
                view.displayPriority = .required
                return view
            case .rider:
                let view = MKAnnotationView(annotation: stop, reuseIdentifier: nil)
                let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                let icon = UIImageView(image: UIImage(systemName: "bicycle", withConfiguration: config))
                icon.tintColor = .white
                let badge = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                badge.backgroundColor = UIColor(Color.matchaGreen)
                badge.layer.cornerRadius = 20
                badge.layer.borderColor = UIColor.white.cgColor
                badge.layer.borderWidth = 3
                icon.center = CGPoint(x: 20, y: 20)
                badge.addSubview(icon)
                view.addSubview(badge)
                view.frame = badge.frame
                view.displayPriority = .required
                view.layer.zPosition = 1
                return view
            }
        }
    }
}
