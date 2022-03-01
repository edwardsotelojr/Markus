//
//  NotificationView.swift
//  Markus WatchKit Extension
//
//  Created by Edward Sotelo Jr on 2/22/22.
//

import SwiftUI

struct NotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var ringAnimation: CGFloat = 0
    var body: some View {
        VStack{
            Text("Meltdown Alert").font(.subheadline)
        }
    }
}
