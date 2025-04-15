//
//  Loading.swift
//  fw_note
//
//  Created by Fung Wing on 15/4/2025.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3) // Semi-transparent background
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .foregroundColor(.white)
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
        }
    }
}
