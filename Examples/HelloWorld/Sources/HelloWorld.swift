import SwiftTUI

struct ContentView: View {
    @State var text: String = ""
    var body: some View {
        VStack {
            HStack { 
                Text("Hello").bold()
                Spacer()
                Text("World").italic()
            }
            .border(.red)
            .background(.blue)

            Spacer() 
            VStack(alignment: .center) {
                TextField("Enter some text", text: $text) { print($0) }
            }
            Spacer()

            HStack { 
                Text("Goodbye").strikethrough()
                Spacer()
                Text("World").underline()
            }
            .background(.red)
            .border()
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
