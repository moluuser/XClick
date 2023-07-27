//
//  ContentView.swift
//  Xclick
//
//  Created by Chenyang on 2023/7/27.
//

import SwiftUI
import AudioToolbox
import HotKey

struct ContentView: View {
    let currentXYTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    @State var clickTimer: Timer?
    
    @State private var mouseLocation = NSEvent.mouseLocation
    
    @State private var isCustiomXY = false
    @State private var isClicking = false
    @State private var isClickingSound = true
    @State private var isAlwaysOnTop = false
    
    @State private var clickX = 0
    @State private var clickY = 0
    
    @State private var clickMaxCount = 0
    @State private var clickCount = 0
    @State private var clickDelay: Double = 1
    
    enum ClickType {
        case left, right
    }
    
    // 1: left click; 2: right click.
    @State private var selectedClickType: ClickType = .left
    
    let hotkeyStart = HotKey(key: .leftBracket, modifiers: .command)
    let hotkeyStop = HotKey(key: .rightBracket, modifiers: .command)
    
    var body: some View {
        VStack {
            HStack {
                Text(String(format: "%.0f", mouseLocation.x))
                Text(",")
                Text(String(format: "%.0f", mouseLocation.y))
            }
            .onReceive(currentXYTimer) { _ in
                mouseLocation = NSEvent.mouseLocation
            }
            
            HStack {
                Toggle(isOn: $isCustiomXY) {
                    Text("Customize Coordinates")
                }
                .padding()
                TextField("", value: $clickX, format: .number).disabled(!isCustiomXY)
                Text(",")
                TextField("", value: $clickY, format: .number).disabled(!isCustiomXY)
            }
            .disabled(isClicking)
            .safeAreaInset(edge: .bottom) {
                Label("If you don't check Customize Coordinates, it will click current position of the mouse.", systemImage: "info.circle")
                    .padding(.top, -10)
            }
            
            HStack {
                Text("Maximum Number of Clicks")
                TextField("", value: $clickMaxCount, format: .number)
            }
            .disabled(isClicking)
            
            HStack {
                Text("Delay between Clicks")
                TextField("", value: $clickDelay, format: .number)
                Text("Seconds")
            }
            .disabled(isClicking)
            
            HStack {
                Picker("Select Click", selection: $selectedClickType) {
                    Text("Left Click").tag(ClickType.left)
                    Text("Right Click").tag(ClickType.right)
                }
            }
            .disabled(isClicking)
            
            HStack {
                Toggle(isOn: $isClickingSound) {
                    Text("Clicking Sound")
                }
                Toggle(isOn: $isAlwaysOnTop) {
                    Text("Always on Top")
                } .onChange(of: isAlwaysOnTop) { _ in
                    if isAlwaysOnTop {
                        for window in NSApplication.shared.windows {
                            window.level = .floating
                        }
                    } else {
                        for window in NSApplication.shared.windows {
                            window.level = .normal
                        }
                    }
                }
            }
            .disabled(isClicking)
            
            HStack {
                Text("Already Made:")
                Text(String(format: "%d", clickCount))
            }
            
            HStack {
                Button{
                    // Start
                    startClick()
                } label: {
                    Label("Start \(Image(systemName: "command")) + [", systemImage: "restart")
                }
                .disabled(isClicking)
                Button {
                    // Stop
                    stopClick()
                    
                } label: {
                    Label("Stop \(Image(systemName: "command")) + ]", systemImage: "stop")
                }
                .disabled(!isClicking)
            }
            
            HStack {
                Button {
                    openSecurityPreferences()
                } label: {
                    Label("Open Security & Privacy Preferences", systemImage: "accessibility")
                }
            }
        }
        .onAppear {
            hotkeyStart.keyDownHandler = startClick
            hotkeyStop.keyDownHandler = stopClick
        }
    }
    
    private func startClick() {
        print("Start")
        isClicking = true
        clickCount = 0
        startTimer(delay: clickDelay)
    }
    
    private func stopClick() {
        print("Stop")
        isClicking = false
        stopTimer()
    }
    
    private func stopTimer() {
        clickTimer?.invalidate()
        clickTimer = nil
    }
    
    private func startTimer(delay: Double) {
        clickTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true, block: { _ in
            clickCount += 1
            if clickMaxCount != 0 && clickCount >= clickMaxCount {
                stopClick()
            }
            
            mouseClick()
        })
    }
    
    private func mouseClick() {
        if let screen = NSScreen.main {
            if isClickingSound {
                AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
            }
            
            let rect = screen.frame
            let height = rect.size.height
            
            let source = CGEventSource.init(stateID: .hidSystemState)
            
            var mouseDownType = CGEventType.leftMouseDown
            var mouseUpType = CGEventType.leftMouseUp
            var mouseType = CGMouseButton.left
            
            if selectedClickType == .right {
                mouseDownType = CGEventType.rightMouseDown
                mouseUpType = CGEventType.rightMouseUp
                mouseType = CGMouseButton.right
            }
            
            var clickLocation: NSPoint = NSPoint(x: mouseLocation.x, y: CGFloat(height) - mouseLocation.y)
            if isCustiomXY {
                clickLocation = NSPoint(x: clickX, y: Int(height) - clickY)
            }
            
            // Click
            print(clickLocation)
            
            let mouseDown = CGEvent(mouseEventSource: source, mouseType: mouseDownType, mouseCursorPosition: clickLocation, mouseButton: mouseType)
            let mouseUp = CGEvent(mouseEventSource: source, mouseType: mouseUpType, mouseCursorPosition: clickLocation, mouseButton: mouseType)
            
            mouseDown?.post(tap: .cghidEventTap)
            mouseUp?.post(tap: .cghidEventTap)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func openSecurityPreferences() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
}
