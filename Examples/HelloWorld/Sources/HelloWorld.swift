import SwiftTUI

struct ContentView: View {
    var body: some View {
        HStack { 
            Text("Hello")
            Spacer()
            Text("World")
        }

        Spacer() 

        HStack { 
            Text("Goodbye")
            Spacer()
            Text("World")
        }
    }
}

@main
struct HelloWorld: App {
    var body: some View {
        ContentView()
    }
}
