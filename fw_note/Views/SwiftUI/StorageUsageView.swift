//
//  StorageUsageView.swift
//  fw_note
//
//  Created by Fung Wing on 21/3/2025.
//

import SwiftUI

struct StorageUsageView: View {
    @State private var freeSpaceRatio: Double = 0.0

    var body: some View {
        VStack(alignment: .leading) {
            Text("Storage Usage")
                .font(.caption)
                .foregroundColor(.gray)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 25)
                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: CGFloat(300 * (1.0 - freeSpaceRatio)), height: 25
                    ).cornerRadius(5)
            }
            .cornerRadius(5)
            .overlay(
                Text("Free Space: \(Int(freeSpaceRatio * 100))%")
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(.horizontal)
            )
           
        }.onAppear{
            freeSpaceRatio = FileHelper.updateFreeSpace()
        }
    
    }
    
   
}
