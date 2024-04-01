//
//  ContentView.swift
//  eskateboard-app
//
//  Created by Andrew Yang on 2024-03-26.
//

import SwiftUI
import CoreBluetooth
    
struct SkateboardData {
    var speed: Float // in km/h
    var distanceRemaining: Float // in km
    var battery: Float // as a percentage
    var distanceTravelled: Float // revolutions per minute
}
enum ErrorType: String, CaseIterable {
    case error = "ERROR"
    case warning = "WARNING"
}
struct ErrorObject {
    var type: ErrorType
    var message: String
}
class BluetoothViewModel : NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var receivedCharacteristicsUUIDs: Set<String> = []
    @Published var peripherals: [CBPeripheral] = []
    @Published private(set) var peripheralNames: [String] = []
    @Published var isConnected = false // Track connection status
    @Published var skateboardData = SkateboardData(speed: 0, distanceRemaining: 0, battery: 100, distanceTravelled: 0)
    @Published var showAlert = false
    @Published var errorObject: ErrorObject? = nil
    let expectedCharacteristicsUUIDs: Set<String> = [
        BluetoothCharacteristicMap.battery.rawValue,
        BluetoothCharacteristicMap.distanceRemaining.rawValue,
        BluetoothCharacteristicMap.speed.rawValue,
        BluetoothCharacteristicMap.distanceTravelled.rawValue
    ]
    enum BluetoothCharacteristicMap: String, CaseIterable {
        case battery = "EC76C264-0BC4-4EAA-B32E-01C723E9CFE3"
        case distanceRemaining = "ABC4AF9E-7220-45E5-BC87-137D35DAFB4D"
        case speed = "B5FA25E0-884E-475A-9A70-A286B88DF9F5"
        case distanceTravelled = "6043959F-C355-40C3-A069-9E511F335793"
    }

    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        
    }
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        self.centralManager?.connect(peripheral, options: nil)
        self.connectedPeripheral = peripheral
    }
    
    func disconnectPeripheral(){
        guard let peripheral = connectedPeripheral else {
                   print("No connected peripheral to disconnect.")
                   return
               }
       if peripheral.state == .connected {
           self.centralManager?.cancelPeripheralConnection(peripheral)
       }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            // Update your isConnected flag and handle any cleanup
           self.isConnected = false
           self.connectedPeripheral = nil
        self.showAlert = false;
        self.errorObject = nil;
            if let error = error {
                print("Disconnected from \(peripheral.name ?? "") due to error: \(error.localizedDescription)")
            } else {
                print("Disconnected from \(peripheral.name ?? "") successfully.")
            }

            // Call any cleanup or UI update methods here
            // For example, call a method to reset UI elements or data models related to the connected device
            onDisconnected?()
        }

        // Method to be called when disconnected successfully
        var onDisconnected: (() -> Void)?

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
    func checkCharacteristicsAfterConnection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Adjust the timeout duration as needed
            let unexpectedUUIDs = self.receivedCharacteristicsUUIDs.subtracting(self.expectedCharacteristicsUUIDs)
            if !unexpectedUUIDs.isEmpty || self.receivedCharacteristicsUUIDs.isEmpty {
                self.errorObject = ErrorObject(type: ErrorType.error, message: "Connected to an incompatible device. Missing characteristics.")
                self.showAlert = true
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "a device")")
        // Handle successful connection, such as stopping scanning and discovering services
        self.isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Pass nil to discover all services; specify UUIDs to find specific ones.
        self.receivedCharacteristicsUUIDs = []
//        checkCharacteristicsAfterConnection()
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
        self.receivedCharacteristicsUUIDs.insert(characteristic.uuid.uuidString)

        enum DataError: Error {
            case invalidSize
        }
        enum ConnectionError: Error {
            case powerOff
            case outOfRange
        }
        do {
            if data.count == MemoryLayout<Float>.size {
                let floatValue = data.withUnsafeBytes { $0.load(as: Float.self) }
                
                print("UUID: \(characteristic.uuid) Float value: \(floatValue)")
                
                // Update corresponding skateboardData properties based on UUID
                switch characteristic.uuid.uuidString {
                case BluetoothCharacteristicMap.battery.rawValue:
                    skateboardData.battery = floatValue
                    if (floatValue < 0) {
                        throw ConnectionError.powerOff
                    }
                case BluetoothCharacteristicMap.distanceTravelled.rawValue:
                    skateboardData.distanceTravelled = floatValue
                case BluetoothCharacteristicMap.speed.rawValue:
                    skateboardData.speed = floatValue
                case BluetoothCharacteristicMap.distanceRemaining.rawValue:
                    skateboardData.distanceRemaining = floatValue
                default:
                    break  // Handle other UUIDs if needed
                }
            } else {
                throw DataError.invalidSize // Manually throw an error
            }
        } catch DataError.invalidSize {
            self.errorObject = ErrorObject(type: ErrorType.error, message: "Invalid data received!")
            self.showAlert = true
        } catch ConnectionError.powerOff {
            self.errorObject = ErrorObject(type: ErrorType.error, message: "Check if skateboard is powered on.")
            self.showAlert = true
        } catch {
            self.errorObject = ErrorObject(type: ErrorType.error, message: "Other error.") 
            self.showAlert = true
        }
    }
}

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
                        .font(.system(size: 28)).bold().padding(.top, 60)
                }
            }
        }
}

struct ConnectedView: View {
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    init(bluetoothViewModel: BluetoothViewModel) {
            self.bluetoothViewModel = bluetoothViewModel
        }
    struct TextItem: Identifiable {
      var id = UUID() // Create a unique identifier for each item
      var text: String
    }
    @State private var fakebattery:Double = 5.0;
    var body: some View {
        VStack(spacing:50) {
            Speedometer()
            BatteryView(battery: .constant(fakebattery), outline: Color.white)
            Slider(value: $fakebattery,in:0.0...100.0).tint(.blue).padding(.top,-70)
            
            VStack(alignment: .leading, spacing: 15){
                HStack {
                    Text("Distance Travelled:").bold().font(.system(size: 26))
                    Text("\(String(format: "%.2f", bluetoothViewModel.skateboardData.distanceTravelled)) km")
                }
                HStack {
                    Text("Distance Remaining:").bold().font(.system(size: 26))
                    Text("\(String(format: "%.2f", bluetoothViewModel.skateboardData.distanceTravelled)) km")
                }
            }
            
//            VStack(spacing: 20) {
//                ForEach([
////                    TextItem(text: "Speed:                  \(String(format: "%.2f", bluetoothViewModel.skateboardData.speed)) km/h"),
//                         TextItem(text: "Distance Travelled:        \(String(format: "%.2f", bluetoothViewModel.skateboardData.distanceTravelled)) km"),
////                      TextItem(text: "Battery:                      \(String(format: "%.2f", bluetoothViewModel.skateboardData.battery))%"),
//                         TextItem(text: "Distance Remaining:            \(Int(round(bluetoothViewModel.skateboardData.distanceRemaining))) km")]) {
//                    item in Text(item.text)
//                        .font(.system(size: 26)).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 20)
//              }
        }.alert(isPresented: $bluetoothViewModel.showAlert) {
            Alert(
                title: Text(bluetoothViewModel.errorObject?.type.rawValue ?? "No error"),
                message: Text(bluetoothViewModel.errorObject?.message ?? "No error"),
                dismissButton: .default(Text("OK")) {
                    if bluetoothViewModel.errorObject?.type == ErrorType.error {
                        bluetoothViewModel.disconnectPeripheral()
                    }
                }
            )
        }
    }
}


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
    ConnectedView(bluetoothViewModel: BluetoothViewModel()).preferredColorScheme(.dark)
}
