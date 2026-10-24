//
//  CafeMapView.swift
//  Osacha
//
//  Where to collect a pickup: the café on a map, its address and hours, and
//  a way to get directions there. The pickup counterpart of the rider map.
//

import SwiftUI
import MapKit

struct CafeMapView: View {
    /// The map's height; checkout shows a smaller one than tracking.
    var mapHeight: CGFloat = 220

    var body: some View {
        VStack(spacing: 0) {
            CafeMap()
                .frame(height: mapHeight)
                .overlay(alignment: .topLeading) {
                    Label("Your order will be waiting here", systemImage: "bag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaDarkGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.matchaCardCream))
                        .padding(12)
                }

            HStack(spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Color.matchaPinkDeep)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.matchaPinkPale))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Osacha café")
                        .font(.subheadline.weight(.semibold))
                    Text(LocalizedStringKey(Cafe.address))
                        .font(.caption)
                        .opacity(0.7)
                    Text(String(format: localized("Open daily %@"), Cafe.hoursText))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.matchaGreen)
                }
                .foregroundStyle(Color.matchaDarkGreen)

                Spacer()

                Button {
                    openDirections()
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.matchaGreen))
                }
                .accessibilityLabel("Directions")
            }
            .padding(14)
            .background(Color.matchaCardCream)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }

    /// Opens Maps with directions from wherever the customer is.
    private func openDirections() {
        let place = MKMapItem(placemark: MKPlacemark(coordinate: Cafe.coordinate))
        place.name = "Osacha café"
        place.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }
}

/// The map under the café's pin. MapKit's own view, so other shops and
/// cafés nearby can be left off and the customer's eye goes to ours.
private struct CafeMap: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.setRegion(MKCoordinateRegion(center: Cafe.coordinate, latitudinalMeters: 900, longitudinalMeters: 900),
                      animated: false)
        let pin = MKPointAnnotation()
        pin.coordinate = Cafe.coordinate
        map.addAnnotation(pin)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.glyphImage = UIImage(systemName: "cup.and.saucer.fill")
            view.markerTintColor = UIColor(Color.matchaPinkDeep)
            view.displayPriority = .required
            return view
        }
    }
}
