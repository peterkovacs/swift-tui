import SwiftTUI

struct ContentView: View {
    @State var text1: String = ""
    @State var text2: String = ""
    @State var text3: String = ""
    @State var text4: String = ""
    @State var text5: String = ""
    @State var mouse: Position = .zero
    @State var innerMouse: Position = .zero

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Text 1", text: $text1) { _ in }.frame(width: 20).border()
            TextField("Text 2", text: $text2) { _ in }.frame(width: 20).border()
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading) {
                    Text("""
                    Lorem ipsum odor amet, consectetuer adipiscing elit. Ipsum himenaeos a aenean id metus. Lacus donec mauris posuere vestibulum leo. Risus convallis ornare bibendum arcu fames penatibus rutrum diam. Mi vehicula est lacus facilisis mi porta? Velit elementum feugiat placerat quisque justo ante ullamcorper porttitor arcu. Montes porttitor habitasse habitasse in augue euismod. Maecenas ultrices amet neque natoque, in aliquet integer.

                    Ligula habitant etiam ornare habitant venenatis. Commodo fermentum eleifend feugiat class tempus. Viverra elementum placerat morbi nec consequat. Metus suspendisse tincidunt mus ornare libero sodales tempus mattis ultricies. Ante laoreet porta, scelerisque finibus ultrices auctor. Vulputate leo laoreet ullamcorper sit est. Fusce eget varius primis; nisi maximus ipsum ullamcorper dictum. Porttitor aptent purus quisque porta urna neque cras netus placerat.

                    Penatibus pharetra sapien ligula eu efficitur quis sem in morbi. Ac pulvinar torquent risus bibendum curae. Ligula bibendum per velit hac sodales nibh; vivamus in aliquet. Curabitur vestibulum curabitur platea tellus finibus felis mi justo. Imperdiet vel facilisis ex habitant vestibulum pulvinar vitae. Neque lacinia interdum himenaeos himenaeos hendrerit bibendum a. Litora pellentesque nibh ac magnis elit eget.

                    """)
                    .frame(width: 100)
                    Text("\(innerMouse)")
                    TextField("Text 3", text: $text3) { _ in }.frame(width: 20).border()
                    TextField("Text 4", text: $text4) { _ in }.frame(width: 20).border()
                    TextField("Text 5", text: $text5) { _ in }.frame(width: 20).border()
                    }
                .onMouseMove { 
                    self.innerMouse = $0
                }
            }
            .frame(width: 50, height: 20)
            .border()

            Text("\(mouse)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onMouseMove { (position: Position) in 
            self.mouse = position
        }
    }
}

@main
struct HelloWorld: App {
    var body: some View {
        ContentView()
    }
}
