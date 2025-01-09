import SwiftTUI

struct ContentView: View {
    var body: some View {
        HStack { 
            Text("Hello").bold()
            Spacer()
            Text("World").italic()
        }.background(.blue)

        Spacer() 

        HStack { 
            Text("Goodbye").strikethrough()
            Spacer()
            Text("World").underline()
        }
        .background(.red)
    }
}

@main
struct HelloWorld: App {
    var body: some View {
        ContentView()
    }
}
