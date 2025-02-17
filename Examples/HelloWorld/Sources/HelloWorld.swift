import SwiftTUI

struct ContentView: View {
    @State var text1: String = ""
    @State var text2: String = ""
    @State var text3: String = ""
    @State var text4: String = ""
    @State var text5: String = ""
    var body: some View {
        ScrollView {
            Text("""
            Lorem ipsum odor amet, consectetuer adipiscing elit. Ipsum himenaeos a aenean id metus. Lacus donec mauris posuere vestibulum leo. Risus convallis ornare bibendum arcu fames penatibus rutrum diam. Mi vehicula est lacus facilisis mi porta? Velit elementum feugiat placerat quisque justo ante ullamcorper porttitor arcu. Montes porttitor habitasse habitasse in augue euismod. Maecenas ultrices amet neque natoque, in aliquet integer.

            Ligula habitant etiam ornare habitant venenatis. Commodo fermentum eleifend feugiat class tempus. Viverra elementum placerat morbi nec consequat. Metus suspendisse tincidunt mus ornare libero sodales tempus mattis ultricies. Ante laoreet porta, scelerisque finibus ultrices auctor. Vulputate leo laoreet ullamcorper sit est. Fusce eget varius primis; nisi maximus ipsum ullamcorper dictum. Porttitor aptent purus quisque porta urna neque cras netus placerat.

            Penatibus pharetra sapien ligula eu efficitur quis sem in morbi. Ac pulvinar torquent risus bibendum curae. Ligula bibendum per velit hac sodales nibh; vivamus in aliquet. Curabitur vestibulum curabitur platea tellus finibus felis mi justo. Imperdiet vel facilisis ex habitant vestibulum pulvinar vitae. Neque lacinia interdum himenaeos himenaeos hendrerit bibendum a. Litora pellentesque nibh ac magnis elit eget.

            Rhoncus odio lacus leo mauris fames quam metus tempus potenti. Luctus eros finibus tincidunt taciti praesent scelerisque mus. Consectetur sem pharetra montes odio risus praesent semper. Adipiscing porta proin aliquam praesent suscipit velit. Posuere commodo pretium viverra, imperdiet diam tortor dis dapibus. Enim mi congue placerat hendrerit ipsum elit cursus. Aliquet luctus erat efficitur pulvinar enim. Diam in hendrerit, pellentesque egestas parturient posuere dapibus amet. Ultricies odio vulputate lacus porttitor integer fames nascetur lobortis porttitor. Montes justo senectus praesent lacus curae sagittis.

            Himenaeos magna egestas; fringilla fringilla nec sollicitudin augue maecenas? Vestibulum imperdiet blandit rhoncus nibh eu maximus quis rutrum litora? Maecenas ligula nisl aliquet lorem cursus scelerisque eu non lobortis. Lobortis sagittis vivamus facilisi porta velit elementum vehicula vulputate. Accumsan augue hac scelerisque auctor taciti inceptos augue malesuada parturient. Scelerisque sem nisl massa laoreet; odio potenti quis orci venenatis. Quisque enim finibus ligula maecenas vestibulum class quam consequat. Maecenas mauris aenean in fringilla per.
            """)
            TextField("Text 1", text: $text1) { _ in }.frame(width: 20).border()
            TextField("Text 2", text: $text2) { _ in }.frame(width: 20).border()
            TextField("Text 3", text: $text3) { _ in }.frame(width: 20).border()
            TextField("Text 4", text: $text4) { _ in }.frame(width: 20).border()
            TextField("Text 5", text: $text5) { _ in }.frame(width: 20).border()
        }
        .frame(width: 50, height: 40)
        .border()
    }
}

@main
struct HelloWorld: App {
    var body: some View {
        ContentView()
    }
}
