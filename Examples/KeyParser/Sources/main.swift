@testable import SwiftTUI
import Foundation
import CUnicode

let input = FileHandle.standardInput
let pipe = Pipe()
let parser = KeyParser.init(fileHandle: pipe.fileHandleForReading)

input.readabilityHandler = { handle in
    let data = handle.availableData

    if data.count == 0 {
        return
    }

    var output = data

    // Print out the individual bytes, omitting \u{1b} if its the first byte.
    // If data contains any ASCII characters, print those as a string.
    if data[0] == 0x1b {
        output = output.dropFirst()
    }

    let printableCharacters = output.map {
        if $0 >= 0x20 && $0 <= 0x7e {
            return String(format: "%c", $0)
        } else {
            return String(format: "\\u{%02x}", $0)       
        }
    }.joined()
    print("\"\(printableCharacters)\": ")

    pipe.fileHandleForWriting.write(data)

}

func write(_ str: String.UTF8View) {
    let written = str.withContiguousStorageIfAvailable { ptr in
        CUnicode.write(FileHandle.standardOutput.fileDescriptor, ptr.baseAddress, ptr.count)
    }

    if written == nil {
        Array(str).withUnsafeBufferPointer { ptr in
            _ = CUnicode.write(FileHandle.standardOutput.fileDescriptor, ptr.baseAddress, ptr.count)
        }
    }
}

var terminalAttributes: termios?
@MainActor func setInputMode() {
    var tattr = termios()
    tcgetattr(FileHandle.standardOutput.fileDescriptor, &tattr)

    if terminalAttributes == nil {
        terminalAttributes = tattr
    }

    //   ECHO: Stop the terminal from displaying pressed keys.
    // ICANON: Disable canonical ("cooked") input mode. Allows us to read inputs
    //         byte-wise instead of line-wise.
    //   ISIG: Disable signals for Ctrl-C (SIGINT) and Ctrl-Z (SIGTSTP), so we
    //         can handle them as "normal" escape sequences.
    // IEXTEN: Disable input preprocessing. This allows us to handle Ctrl-V,
    //         which would otherwise be intercepted by some terminals.
    // tattr.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)
    tattr.c_lflag &= ~tcflag_t(ECHO | ICANON)

    //   IXON: Disable software control flow. This allows us to handle Ctrl-S
    //         and Ctrl-Q.
    //  ICRNL: Disable converting carriage returns to newlines. Allows us to
    //         handle Ctrl-J and Ctrl-M.
    // BRKINT: Disable converting sending SIGINT on break conditions. Likely has
    //         no effect on anything remotely modern.
    //  INPCK: Disable parity checking. Likely has no effect on anything
    //         remotely modern.
    // ISTRIP: Disable stripping the 8th bit of characters. Likely has no effect
    //         on anything remotely modern.
    tattr.c_iflag &= ~tcflag_t(IXON | ICRNL | BRKINT | INPCK | ISTRIP)

    // Disable output processing. Common output processing includes prefixing
    // newline with a carriage return.
    // tattr.c_oflag &= ~tcflag_t(OPOST)

    // Set the character size to 8 bits per byte. Likely has no effect on
    // anything remotely modern.
    // tattr.c_cflag &= ~tcflag_t(CS8)

    // from <termios.h>
    // #define VMIN            16      /* !ICANON */
    // #define VTIME           17      /* !ICANON */
    tattr.c_cc.16 = 0
    tattr.c_cc.17 = 0

    tcsetattr(FileHandle.standardOutput.fileDescriptor, TCSAFLUSH, &tattr);
}

setInputMode()
write(EscapeSequence.enableCellMotionTracking)
write(EscapeSequence.enableExtendedMouseMode)
write(EscapeSequence.enableSendEventsMode)

for try await key in parser { 
    if key == .init("d", modifiers: .ctrl) {
        break
    }

    print("KEY: \(key)")
}

write(EscapeSequence.disableCellMotionTracking)
write(EscapeSequence.disableExtendedMouseMode)
write(EscapeSequence.disableSendEventsmode)
