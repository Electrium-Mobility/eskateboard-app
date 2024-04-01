//
//  Speedometer.swift
//  eskateboard-app
//
//  Created by Andrew Yang on 2024-03-31.
//

import SwiftUI

let MAX_SPEED:Double = 25.0;

struct Speedometer : View {
    @State var currentSpeed: Double = 0;

    var body : some View  {
        VStack {
            Meter(currentSpeed: $currentSpeed)
            Text(String(currentSpeed)+" km/h").padding(.vertical, 50).font(.system(size: 20))
            HStack(spacing:25){
                Button(action: {
                    
                    withAnimation(Animation.default.speed(2)) {
                        if self.currentSpeed < MAX_SPEED {
                            self.currentSpeed += 1;
                        }
                    }
                }, label: {
                    Text("Update")
                })
                Button(action:{
                    withAnimation(Animation.default.speed(0.55)) {
                        self.currentSpeed = 0;
                    }
                }
                       , label: {
                    Text("Reset")
                })
            }.padding(.top, 60)
        }
    }
    
    
}
struct Meter : View {
    let colors = [Color(red: 0.0, green: 1.0, blue:0.0),Color(red: 1.0, green: 0.0, blue:0.0),Color(red: 1.0, green: 0.0, blue:0.0),Color(red: 1.0, green: 0.0, blue:0.0)]
    @Binding var currentSpeed: Double


    var body : some View {
        ZStack {
            ZStack {
                Circle().trim(from:0,to: 0.5).stroke(Color.white.opacity(0.8),lineWidth: 55).frame(width: 280,height:280)
                Circle().trim(from:0,to: setSpeedometer()).stroke(AngularGradient(gradient: .init(colors: self.colors), center: .center, angle: .init(degrees: 0)),lineWidth: 55).frame(width: 280,height:280)
            }.rotationEffect(.init(degrees: 180))
            ZStack(alignment: .bottom) {
                Color.blue.frame(width: 2, height: 100)
                Circle().fill(Color.blue).frame(width: 15, height: 15)
            }.offset(y:-40).rotationEffect(.init(degrees:-90)).rotationEffect(.init(degrees: self.setArrow()))
        }.padding(.bottom,-140)
    }
    func setSpeedometer()->Double {
        return Double(self.currentSpeed/MAX_SPEED * 0.5)
    }
    func setArrow()->Double{
        return Double(self.currentSpeed/MAX_SPEED*180);
    }
}

#Preview {
    Speedometer()
}
