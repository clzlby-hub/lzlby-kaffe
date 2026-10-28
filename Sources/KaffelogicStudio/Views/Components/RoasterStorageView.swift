import SwiftUI

public struct RoasterStorageView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "externaldrive.badge.wifi")
                    .font(.title2)
                    .foregroundColor(.green)
                Text(loc("view_roaster")).font(.headline)
                Spacer()
            }
            Divider()
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kaffelogic Nano 7 存储空间").font(.subheadline.bold())
                    Text("机身固件: v7.21.6 (RP2040) · USB-CDC 就绪").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text("已用 18% (4.2 MB / 16 MB)").font(.caption.monospaced()).foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            List {
                Section("烘焙方案 (Roast Profiles)") {
                    Label("(KL) Classic v1.8.kpro", systemImage: "chart.xyaxis.line")
                    Label("(KL) Explorer v1.1.kpro", systemImage: "chart.xyaxis.line")
                    Label("Kenya Nyeri Peaberry.kpro", systemImage: "chart.xyaxis.line")
                }
                Section("历史烘焙记录 (Roast Logs)") {
                    Label("2026-10-27_Yirgacheffe_L3.4.klog", systemImage: "doc.text")
                    Label("2026-10-25_Geisha_Wash_L2.8.klog", systemImage: "doc.text")
                }
            }
            .listStyle(.inset)
            .frame(height: 200)
            
            HStack {
                Button("打开本地同步文件夹") { state.openSyncFolder() }
                Spacer()
                Button(loc("close")) { dismiss() }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
