import SwiftTUI

struct ContentView: View {
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
