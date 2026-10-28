import Foundation
import Combine
import SwiftUI

public enum DeviceConnectionState: Equatable {
    case disconnected
    case connectedUSB(port: String)
    case connectedWiFi(ip: String)
    case simulated
    
    public var description: String {
        switch self {
        case .disconnected: return loc("device_disconnected")
        case .connectedUSB(let port): return "\(loc("device_connected_usb")) (\(port))"
        case .connectedWiFi(let ip): return "\(loc("device_connected_wifi")) (\(ip))"
        case .simulated: return loc("device_simulated")
        }
    }
    
    public var isConnected: Bool {
        if case .disconnected = self { return false }
        return true
    }
}

public class DeviceManager: ObservableObject {
    public static let shared = DeviceManager()
    
    @Published public var state: DeviceConnectionState = .disconnected
    @Published public var currentBeanTemp: Double = 22.0
    @Published public var currentRoR: Double = 0.0
    @Published public var currentPower: Double = 0.0
    @Published public var currentFanRPM: Double = 0.0
    @Published public var elapsedTime: Double = 0.0
    @Published public var isRoasting: Bool = false
    
    private var simulationTimer: Timer?
    private var usbMonitorTimer: Timer?
    private var activeProfile: RoastProfile?
    
    public init() {
        startAutoUSBMonitoring()
    }
    
    // MARK: - 后台自动监听 USB 串口设备 (插上自动连，拔掉自动断，完全无感)
    public func startAutoUSBMonitoring() {
        usbMonitorTimer?.invalidate()
        usbMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkForUSBRoaster()
        }
    }
    
    private func checkForUSBRoaster() {
        // 如果正在模拟烘焙，不干扰模拟状态
        if case .simulated = state { return }
        
        // 扫描 /dev 目录下的 USB CDC 调制解调器串口 (RP2040 插入时自动创建)
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(atPath: "/dev") else { return }
        
        let usbPorts = files.filter { $0.hasPrefix("cu.usbmodem") || $0.hasPrefix("tty.usbmodem") }
        
        DispatchQueue.main.async {
            if let detectedPort = usbPorts.first {
                if case .connectedUSB(let existingPort) = self.state, existingPort == detectedPort {
                    // 已连接同一端口，保持状态
                } else {
                    // 自动连接上新插入的 USB 机器！
                    self.state = .connectedUSB(port: detectedPort)
                }
            } else {
                // USB 已断开
                if case .connectedUSB = self.state {
                    self.state = .disconnected
                }
            }
        }
    }
    
    // MARK: - 手动触发重新扫描
    public func scanManually() {
        checkForUSBRoaster()
    }
    
    // MARK: - 烘焙模拟演示
    public func startSimulation(with profile: RoastProfile) {
        stop()
        self.activeProfile = profile
        self.state = .simulated
        self.isRoasting = true
        self.elapsedTime = 0.0
        self.currentBeanTemp = 24.0
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let profile = self.activeProfile else { return }
            self.elapsedTime += 0.5
            let target = BezierMath.valueAt(time: self.elapsedTime, points: profile.roastProfilePoints) ?? 220.0
            let diff = target - self.currentBeanTemp
            let step = diff * 0.04 + Double.random(in: -0.15...0.15)
            self.currentBeanTemp += step
            self.currentRoR = max(0, (step / 0.5) * 60.0)
            self.currentFanRPM = BezierMath.valueAt(time: self.elapsedTime, points: profile.fanProfilePoints) ?? 14000
            self.currentPower = max(0.2, min(1.35, (profile.roastRequiredPower / 1000.0) * (diff > 5 ? 1.0 : 0.6)))
            if let maxT = profile.roastProfilePoints.last?.x, self.elapsedTime >= maxT {
                self.stop()
            }
        }
    }
    
    public func stop() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isRoasting = false
        if case .simulated = state {
            state = .disconnected
        }
    }
}
