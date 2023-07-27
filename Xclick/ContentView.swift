//
//  ContentView.swift
//  Xclick
//
//  Created by Chenyang on 2023/7/27.
//

import SwiftUI

struct ContentView: View {
    let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    @State private var mouseLocation = NSEvent.mouseLocation
    
    @State private var isCustiomXY = false
    @State private var isClicking = false
    @State private var isClickingSound = true
    
    @State private var clickX = 0
    @State private var clickY = 0
    
    @State private var clickMaxCount = 0
    @State private var clickDelay = 0
    
    @State private var selectedClickType = 1
    
    var body: some View {
        VStack {
            HStack {
                Text(mouseLocation.x.formatted())
                Text(mouseLocation.y.formatted())
            }
            .onReceive(timer) { _ in
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
                Label("If you don't check Customize Coordinates, it will click on the current position of the mouse.", systemImage: "info.circle")
                    .padding(.top, -10)
            }
            
            HStack {
                Text("Maximum Number of Clicks")
                TextField("", value: $clickMaxCount, format: .number)
            }
            .disabled(isClicking)
            
            HStack {
                Text("Delay between Clicks (Seconds)")
                TextField("", value: $clickDelay, format: .number)
            }
            .disabled(isClicking)
            
            HStack {
                Picker("Select Click", selection: $selectedClickType) {
                    Text("Left Click").tag(1)
                    Text("Right Click").tag(2)
                }
            }
            .disabled(isClicking)
            
            HStack {
                Toggle(isOn: $isClickingSound) {
                    Text("\(isClickingSound ? "Clicking Sound" : "No Clicking Sound")")
                }
            }
            .disabled(isClicking)
            
            HStack {
                Button{
                    isClicking = true
                    
                } label: {
                    Label("Start \(Image(systemName: "command")) + [", systemImage: "restart")
                }
                .disabled(isClicking)
                .keyboardShortcut("[", modifiers: .command)
                Button{
                    isClicking = false
                    
                } label: {
                    Label("Stop \(Image(systemName: "command")) + ]", systemImage: "stop")
                }
                .disabled(!isClicking)
                .keyboardShortcut("]", modifiers: .command)
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
