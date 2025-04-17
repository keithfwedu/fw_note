//
//  ToastView.swift
//  fw_note
//
//  Created by Fung Wing on 17/4/2025.
//

import SwiftUICore

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(radius: 10)
    }
}
