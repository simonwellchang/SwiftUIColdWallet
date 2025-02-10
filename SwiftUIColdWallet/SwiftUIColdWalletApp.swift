//
//  SwiftUIColdWalletApp.swift
//  SwiftUIColdWallet
//
//  Created by Mac on 2025/2/10.
//

import SwiftUI
import CoreBluetooth
import CryptoKit

// MARK: - 藍牙管理器
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var devices: [CBPeripheral] = []
    @Published var connectedDevice: CBPeripheral?
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !devices.contains(peripheral) {
            devices.append(peripheral)
        }
    }
    
    func connect(to device: CBPeripheral) {
        centralManager.stopScan()
        connectedDevice = device
        centralManager.connect(device, options: nil)
    }
}

// MARK: - 助記詞 & 錢包地址管理
class WalletManager: ObservableObject {
    @Published var mnemonic: String = ""
    @Published var walletAddress: String = ""
    
    func generateMnemonic() {
        let words = (0..<12).map { _ in UUID().uuidString.prefix(4) }.joined(separator: " ")
        mnemonic = words
        walletAddress = "1BitcoinAddressXXXXXXX" // 這裡應該用 BIP39 來生成真正的地址
    }
    
    func signTransaction() -> String {
        let message = "SampleTransactionData"
        let key = SymmetricKey(size: .bits256)
        let signature = HMAC<SHA256>.authenticationCode(for: message.data(using: .utf8)!, using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - SwiftUI 介面
struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var walletManager = WalletManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("冷錢包 Demo").font(.largeTitle).padding()
                
                // 助記詞生成
                Button("生成助記詞") {
                    walletManager.generateMnemonic()
                }
                Text(walletManager.mnemonic).padding()
                
                // 顯示比特幣地址
                Text("地址: \(walletManager.walletAddress)")
                    .padding()
                    .font(.headline)
                
                // 簽署交易
                Button("簽署交易") {
                    let signedTx = walletManager.signTransaction()
                    print("簽名交易: \(signedTx)")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                // 藍牙設備列表
                List(bluetoothManager.devices) { device in
                    Button(device.name ?? "未知設備") {
                        bluetoothManager.connect(to: device)
                    }
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension CBPeripheral: @retroactive Identifiable {
    public var id: UUID {
        return self.identifier
    }
}

// MARK: - App 主入口
@main
struct ColdWalletApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

