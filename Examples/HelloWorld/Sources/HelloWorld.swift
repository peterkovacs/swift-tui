import SwiftTUI

struct ContentView: View {
    var body: some View {
        HStack { 
            Text("Hello").bold()
            Spacer()
            Text("World").italic()
        }

        Spacer() 

        HStack { 
            Text("Goodbye").strikethrough()
            Spacer()
            Text("World").underline()
        }
    }
}

@main
struct HelloWorld: App {
    var body: some View {
        ContentView()
    }
}
