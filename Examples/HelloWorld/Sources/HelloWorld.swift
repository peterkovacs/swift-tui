import SwiftTUI

struct ContentView: View {
    @State var text1: String = ""
    @State var text2: String = ""
    @State var text3: String = ""
    @State var text4: String = ""
    @State var text5: String = ""
    var body: some View {
        VStack {
            TextField("Text 1", text: $text1) { _ in }.frame(width: 20).border()
            TextField("Text 2", text: $text2) { _ in }.frame(width: 20).border()
            TextField("Text 3", text: $text3) { _ in }.frame(width: 20).border()
            TextField("Text 4", text: $text4) { _ in }.frame(width: 20).border()
            TextField("Text 5", text: $text5) { _ in }.frame(width: 20).border()
        }
        .border()
    }
}

@main
struct HelloWorld: App {
    var body: some View {
        ContentView()
    }
}
