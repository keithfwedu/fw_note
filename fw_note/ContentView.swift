//
//  ContentView.swift
//  fw_note
//
//  Created by Fung Wing on 13/3/2025.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var canvasSettings = CanvasSettings()
    
    var body: some View {
        
        CanvasView().environmentObject(canvasSettings)
    }

}
