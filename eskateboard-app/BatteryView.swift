//
//  BatteryView.swift
//  eskateboard-app
//
//  Created by Andrew Yang on 2024-03-31.
//

import SwiftUI

struct BatteryView :View {
    @Binding var battery: Double
    let outline: Color
    @State private var opacity = 0.0
    var body : some View{
        ZStack {
            Image(systemName: "battery.0").resizable().scaledToFit().font(.headline.weight(.ultraLight)).foregroundColor(outline).background(Rectangle().fill(batteryColor()).scaleEffect(x: battery/100.0,y:1,anchor: .leading)).mask(Image(systemName: "battery.100").resizable().scaledToFit().font(.headline.weight(.ultraLight))).frame(width: 240).padding()
            
            Text(String(format: "%.1f", battery)+"%").foregroundColor(self.battery > 10 ? .white : .red).animation(nil).padding(.leading,-20)
        }
    }
    func batteryColor()->Color {
        if (battery > 50) {return Color.green}
            else if (battery > 20) {return Color.orange}
            else {return Color.red}
    }
}

#Preview {
    BatteryView(battery: .constant(35.0), outline: Color.white).preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
}
