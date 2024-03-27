//
//  ContentView.swift
//  eskateboard-app
//
//  Created by Andrew Yang on 2024-03-26.
//

import SwiftUI
import CoreBluetooth

struct SkateboardData {
    var speed: Double // in km/h
    var range: Double // in km
    var battery: Float // as a percentage
    var rpm: Int // revolutions per minute
}

var BluetoothCharacteristicMap = [
    "BATTERY": "EC76C264-0BC4-4EAA-B32E-01C723E9CFE3"
]

class BluetoothViewModel : NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    @Published var peripherals: [CBPeripheral] = []
    @Published private(set) var peripheralNames: [String] = []
    @Published var isConnected = false // Track connection status
    @Published var skateboardData = SkateboardData(speed: 0, range: 0, battery: 100, rpm: 0)

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        self.centralManager?.connect(peripheral, options: nil)
    }
    var onConnercted: (() -> Void)?
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "unnamed device")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "a device")")
        // Handle successful connection, such as stopping scanning and discovering services
        self.isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Pass nil to discover all services; specify UUIDs to find specific ones.
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "a device") with error: \(error?.localizedDescription ?? "unknown error")")
        // Handle connection failure
    }

}
extension BluetoothViewModel: CBPeripheralDelegate {
    // Called when services have been discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            // Step 2: Discover Characteristics for each service
            peripheral.discoverCharacteristics(nil, for: service) // Pass nil to discover all characteristics
        }
    }
    
    // Called when characteristics have been discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // Step 3: Subscribe to characteristics
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    // Called when there's a notification/indication of a characteristic's value
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        // Handle the incoming data
//        print("Received data: \(data)")
        // Convert to float if needed
            if data.count == MemoryLayout<Float>.size {
                let floatValue = data.withUnsafeBytes { $0.load(as: Float.self) }
                print("UUID: \(characteristic.uuid) Float value: \(floatValue)")
                if characteristic.uuid.uuidString == BluetoothCharacteristicMap["BATTERY"] {
                    skateboardData.battery = floatValue
                }
            }
        
        // Convert to a string if needed
        if let string = String(data: data, encoding: .utf8) {
            print("String representation: \(string)")
        }
    }
}

//class SkateboardViewModel: ObservableObject {
//    @Published var data = SkateboardData(speed: 0, range: 0, battery: 100, rpm: 0)
//    
//    // Assume this method is called whenever new BLE data is received
//    func updateData(speed: Double, range: Double, battery: Int, rpm: Int) {
//        data = SkateboardData(speed: speed, range: range, battery: battery, rpm: rpm)
//    }
//}

struct DisconnectedView: View {
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @Binding var isLoading: Bool
   
    var body: some View {
            List {
                ForEach(bluetoothViewModel.peripherals, id: \.self) { peripheral in
                    if let name = peripheral.name{
                        Text(name)
                            .onTapGesture {
                                isLoading = true
                                bluetoothViewModel.connectToPeripheral(peripheral)
                                isLoading = false
                            }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Connect to the Skateboard")
                        .font(.system(size: 25))
                }
            }
        }
}

struct ConnectedView: View {
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    init(bluetoothViewModel: BluetoothViewModel) {
            self.bluetoothViewModel = bluetoothViewModel
        }
    var body: some View {
        VStack {
            Text("Speed: \(bluetoothViewModel.skateboardData.speed) km/h")
            Text("Range: \(bluetoothViewModel.skateboardData.range) km")
            Text("Battery: \(bluetoothViewModel.skateboardData.battery)%")
            Text("RPM: \(bluetoothViewModel.skateboardData.rpm)")
        }}
}
//struct SkateboardView: View {
//    @ObservedObject var viewModel = SkateboardViewModel()
//    
//    var body: some View {
//        VStack {
//            Text("Speed: \(viewModel.data.speed) km/h")
//            Text("Range: \(viewModel.data.range) km")
//            Text("Battery: \(viewModel.data.battery)%")
//            Text("RPM: \(viewModel.data.rpm)")
//        }
//    }
//}

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
                else if bluetoothViewModel.isConnected {
                // Display a view when connected
                ConnectedView(bluetoothViewModel: bluetoothViewModel)
            } else {
                // The original list view to select and connect to a device
                DisconnectedView(bluetoothViewModel: bluetoothViewModel, isLoading: $isLoading)
            }
        }
    }
}

#Preview {
    ContentView()
}
