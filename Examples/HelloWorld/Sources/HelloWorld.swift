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

            ScrollView {
                Text(
                    """
                    Lorem ipsum odor amet, consectetuer adipiscing elit. Dignissim arcu dictum potenti; ut elit semper. Semper vitae aenean dictum curae est vehicula. Porttitor lacus sapien feugiat bibendum sed imperdiet ornare gravida. Commodo dui taciti class conubia sollicitudin. Montes eu integer donec commodo vitae ornare. Cursus platea tristique elit aenean accumsan volutpat sit tincidunt.

                    Diam eget a pulvinar aenean turpis efficitur. Sodales nullam quis varius, netus primis netus accumsan ultrices pharetra. Luctus elit sed finibus velit mus nullam cursus. Curabitur felis molestie sagittis elit blandit. Conubia montes ligula felis faucibus augue lectus per. Finibus rutrum condimentum laoreet dictumst eros mus platea.

                    Enim massa morbi; tempor odio tellus feugiat magnis. Egestas sit turpis, ridiculus lorem tincidunt suscipit. Mauris vulputate vel dapibus mauris purus vitae? Habitasse lobortis sodales conubia; aliquet id magnis eget placerat. Varius molestie magnis nisl eros montes montes convallis. Habitasse ex massa est ut dictum tincidunt nascetur per?

                    Inceptos donec ipsum pellentesque natoque, ipsum habitant aptent massa. Fermentum neque nisl fermentum, vestibulum accumsan cubilia? Amet donec euismod; est cursus sagittis ridiculus sagittis nam cubilia. Dignissim tincidunt taciti sollicitudin primis sem; faucibus mollis vehicula. Diam turpis laoreet viverra torquent aenean. Primis amet proin varius sed odio consectetur elit proin semper. Praesent est per eget placerat auctor.

                    Torquent dolor adipiscing nam dictum morbi. Tortor interdum purus magnis varius hendrerit tempus dui. Ornare ullamcorper dui luctus magnis mus eget ultrices feugiat. Nulla mollis ullamcorper pharetra, feugiat sociosqu pretium. Venenatis leo tempor lacinia lorem finibus hendrerit potenti. Tempor taciti lobortis eget lectus arcu tempor imperdiet nisi. Rhoncus amet etiam justo duis pharetra dui. Natoque euismod vitae leo, mus nisl duis. Convallis hac sollicitudin porttitor nostra porttitor orci nullam dui.
                    """
                )
            }

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
