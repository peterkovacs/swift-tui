import Foundation

public enum EscapeSequence {
    public static let clearScreen = "\u{1b}[2J".utf8

    public static let enableAlternateBuffer = "\u{1b}[?1049h".utf8
    public static let disableAlternateBuffer = "\u{1b}[?1049l".utf8

    public static let showCursor = "\u{1b}[?25h".utf8
    public static let hideCursor = "\u{1b}[?25l".utf8

    public static func moveTo(_ position: Position) -> String.UTF8View {
        "\u{1b}[\(position.line + 1);\(position.column + 1)H".utf8
    }

    public static func setForegroundColor(_ color: ANSIColor) -> String.UTF8View {
        "\u{1b}[\(color.foregroundCode)m".utf8
    }

    public static func setBackgroundColor(_ color: ANSIColor) -> String.UTF8View {
        "\u{1b}[\(color.backgroundCode)m".utf8
    }

    public static func setForegroundColor(red: Int, green: Int, blue: Int) -> String.UTF8View {
        "\u{1b}[38;2;\(red);\(green);\(blue)m".utf8
    }

    public static func setBackgroundColor(red: Int, green: Int, blue: Int) -> String.UTF8View {
        "\u{1b}[48;2;\(red);\(green);\(blue)m".utf8
    }

    public static func setForegroundColor(xterm: Int) -> String.UTF8View {
        "\u{1b}[38;5;\(xterm)m".utf8
    }

    public static func setBackgroundColor(xterm: Int) -> String.UTF8View {
        "\u{1b}[48;5;\(xterm)m".utf8
    }

    public static let enableBold = "\u{1b}[1m".utf8
    public static let disableBold = "\u{1b}[22m".utf8

    public static let enableItalic = "\u{1b}[3m".utf8
    public static let disableItalic = "\u{1b}[23m".utf8

    public static let enableUnderline = "\u{1b}[4m".utf8
    public static let disableUnderline = "\u{1b}[24m".utf8

    public static let enableStrikethrough = "\u{1b}[9m".utf8
    public static let disableStrikethrough = "\u{1b}[29m".utf8

    public static let enableInverted = "\u{1b}[7m".utf8
    public static let disableInverted = "\u{1b}[27m".utf8
}
