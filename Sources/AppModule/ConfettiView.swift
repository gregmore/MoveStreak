import SwiftUI

struct ConfettiBurst: View {
    var trigger: Int
    var colors: [Color] = [.cyan, .blue, .purple, .pink, .yellow, .mint]
    var duration: TimeInterval = 1.25
    
    @State private var seed: Int = 0
    @State private var startDate = Date()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let progress = max(0, min(1, elapsed / duration))
            
            Canvas { context, size in
                guard progress < 1 else { return }
                
                let count = 90
                let t = progress
                let g = CGFloat(1.0 - t)
                
                for i in 0..<count {
                    let r = random(i, salt: 0)
                    let c = colors[Int(abs(r * 1000).truncatingRemainder(dividingBy: Double(colors.count)))]
                    
                    let angle = CGFloat(random(i, salt: 1) * Double.pi * 2)
                    let speed = CGFloat(120 + random(i, salt: 2) * 260)
                    let spin = CGFloat(random(i, salt: 3) * 10 - 5)
                    let dx = cos(angle) * speed * CGFloat(t)
                    let dy = sin(angle) * speed * CGFloat(t) + CGFloat(520) * CGFloat(t * t)
                    
                    let x = size.width * 0.5 + dx
                    let y = size.height * 0.18 + dy
                    let w = CGFloat(5 + random(i, salt: 4) * 8) * g
                    let h = CGFloat(8 + random(i, salt: 5) * 12) * g
                    
                    var ctx = context
                    ctx.opacity = 0.9 * Double(g)
                    ctx.addFilter(.shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1))
                    
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    let path = Path(roundedRect: rect, cornerRadius: w * 0.3)
                    
                    let rot = Angle(radians: Double(angle) + Double(spin) * Double(t))
                    ctx.rotate(by: rot)
                    ctx.fill(path, with: .color(c))
                    ctx.rotate(by: -rot)
                }
            }
            .allowsHitTesting(false)
        }
        .onChange(of: trigger) {
            seed += 1
            startDate = Date()
        }
        .opacity(trigger == 0 ? 0 : 1)
    }
    
    private func random(_ i: Int, salt: Int) -> Double {
        var x = UInt64(i &+ salt &+ seed &* 7919 &+ 11)
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        let n = Double(x &* 2685821657736338717) / Double(UInt64.max)
        return n - floor(n)
    }
}
