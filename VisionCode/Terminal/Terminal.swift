//
//  Terminal.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/21/24.
//

import SwiftUI
import VCRemoteCommandCore

struct Prompt: View {
    @Binding var commandState: CommandState
    @Binding var inputText: String
    
    var onSubmit: (() -> ())?
    var body: some View {
        HStack {
            if (commandState == .available) {
                Image(systemName: "chevron.forward.square")
            } else {
                ProgressView()
            }
            Spacer()
            TextField("", text: $inputText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                    self.onSubmit?()
                }
        }

    }
}

struct HistoryView: View {
    @Binding var text:String
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView{
                VStack {
                    Spacer()
                        .frame(maxHeight: .infinity)
                    HStack {
                        Text(text)
                            .multilineTextAlignment(.leading)
                            .padding()
                        Spacer()
                    }
                }
                .frame(minHeight: geometry.size.height)
            }
            .defaultScrollAnchor(.bottom)
        }
    }
}

struct TerminalHeader: View {
    var text: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(text).font(.largeTitle)
            Spacer()
        }
    }
}

struct TerminalView: View {
    @ObservedObject var state: TerminalViewState
    
    var body: some View {
        switch(state.connectionState) {
        case .connected:
            VStack {
                TerminalHeader(text: state.title).padding()
                Spacer()
                HistoryView(text: $state.historyText)
                    .background(.regularMaterial)
                Prompt(commandState: $state.commandState,
                       inputText: $state.commandInputText,
                       onSubmit: state.onExecute)
                    .padding()
                    .background(.thickMaterial)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            Text(error.localizedDescription)
        case .connecting:
            Text("Loading...")
        case .notStarted:
            Text("Not even loading")
        }
    }
}

#Preview {
    TerminalView(state: TerminalViewState(title: "Michael's Macbook Pro",
                                  historyText:  "> cat test.txt\nThis is a test\n",
                                  commandInputText: "cat test.txt",
                                          connectionState: .connected,
                                          commandState: .executing))
}
