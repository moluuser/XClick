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
    
    @State private var isCustomXY = false
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
                Text(NSLocalizedString("mouse_location", comment: ""))
                Text(String(format: "%.0f", mouseLocation.x))
                Text(",")
                Text(String(format: "%.0f", mouseLocation.y))
            }
            .onReceive(currentXYTimer) { _ in
                mouseLocation = NSEvent.mouseLocation
            }
            
            HStack {
                Toggle(isOn: $isCustomXY) {
                    Text(NSLocalizedString("customize_coordinates", comment: ""))
                }
                .padding()
                TextField("", value: $clickX, format: .number)
                    .disabled(!isCustomXY)
                    .frame(width: 60)
                Text(",")
                TextField("", value: $clickY, format: .number)
                    .disabled(!isCustomXY)
                    .frame(width: 60)
            }
            .disabled(isClicking)
            .safeAreaInset(edge: .bottom) {
                Label(NSLocalizedString("customize_coordinates_info", comment: ""), systemImage: "info.circle")
                    .padding(.top, -10)
            }
            
            HStack {
                Text(NSLocalizedString("maximum_number_of_clicks", comment: ""))
                TextField("", value: $clickMaxCount, format: .number)
                    .frame(width: 60)
            }
            .disabled(isClicking)
            
            HStack {
                Text(NSLocalizedString("delay_between_clicks", comment: ""))
                TextField("", value: $clickDelay, format: .number)
                    .frame(width: 60)
                Text(NSLocalizedString("seconds", comment: ""))
            }
            .disabled(isClicking)
            
            HStack {
                Picker(NSLocalizedString("click_type", comment: ""), selection: $selectedClickType) {
                    Text(NSLocalizedString("left_click", comment: "")).tag(ClickType.left)
                    Text(NSLocalizedString("right_click", comment: "")).tag(ClickType.right)
                }
                .frame(width: 200)
            }
            .disabled(isClicking)
            
            HStack {
                Toggle(isOn: $isClickingSound) {
                    Text(NSLocalizedString("clicking_sound", comment: ""))
                }
                Toggle(isOn: $isAlwaysOnTop) {
                    Text(NSLocalizedString("always_on_top", comment: ""))
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
                Text(NSLocalizedString("already_clicked", comment: ""))
                Text(String(format: "%d", clickCount))
            }
            
            HStack {
                Button{
                    // Start
                    startClick()
                } label: {
                    Label("\(NSLocalizedString("start", comment: "")) \(Image(systemName: "command")) + [", systemImage: "restart")
                }
                .disabled(isClicking)
                Button {
                    // Stop
                    stopClick()
                    
                } label: {
                    Label("\(NSLocalizedString("stop", comment: "")) \(Image(systemName: "command")) + ]", systemImage: "stop")
                }
                .disabled(!isClicking)
            }
            
            HStack {
                Button {
                    openSecurityPreferences()
                } label: {
                    Text(NSLocalizedString("open_accessibility", comment: ""))
                }
            }
        }
        .padding()
        .onAppear {
            hotkeyStart.keyDownHandler = startClick
            hotkeyStop.keyDownHandler = stopClick
        }
        .frame(width: 300, height: 400)
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
            if isCustomXY {
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
