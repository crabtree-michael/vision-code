//
//  Terminal.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/21/24.
//

import SwiftUI
import VCRemoteCommandCore

struct TerminalView: View {
    @ObservedObject var state: TerminalViewState
    
    var body: some View {
        XTerm(connection: state.connection)
            .padding()
            .background(.ultraThickMaterial)
            .clipShape(.rect(cornerRadius: 5))
    }
}

#Preview {
    TerminalView(state: TerminalViewState(connection:
                                            Connection(connection: RCConnection(host: "", port: 0, username: "", password: ""),
                                                       state: ConnectionViewState())))
}
