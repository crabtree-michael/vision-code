//
//  QuickOpenView.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/8/24.
//

import SwiftUI

class QuickOpenViewState: ObservableObject {
    @Published var query: String
    @Published var files: [File]
    
    init(query: String, files: [File]) {
        self.query = query
        self.files = files
    }
}

struct FirstResponderTextField: UIViewRepresentable {
    typealias UIViewType = UITextField

    @Binding var text: String
    @Binding var becomeFirstResponder: Bool
   

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator,
                            action: #selector(context.coordinator.textFieldDidChange),
                            for: .editingChanged)
        textField.autocapitalizationType = .none
        return textField
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func updateUIView(_ textField: UITextField, context: Context) {
        textField.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        if text != textField.text {
            textField.text = text
        }
        if self.becomeFirstResponder {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
                self.becomeFirstResponder = false
            }
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            self._text = text
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            self.text = textField.text ?? ""
        }
    }
}

struct QuickOpenView: View {
    @ObservedObject var state: QuickOpenViewState
    
    @State private var becomeFirstResponder = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.title)
                    .padding(.leading)
                FirstResponderTextField(text: $state.query,
                                        becomeFirstResponder: $becomeFirstResponder)
                .frame(maxHeight: 65)
            }
            
            .background(.white.opacity(0.25))
            .clipShape(.rect(cornerSize: CGSize(width: 25, height: 25)))
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 12)
            
            
            ScrollView {
                VStack {
                    ForEach(state.files, id: \.path) { file in
                        VStack(alignment: .leading) {
                            HStack {
                                HStack {
                                    Image(systemName: file.icon.rawValue)
                                    Text(file.name)
                                        .font(.largeTitle)
                                }
                                Spacer()
                            }
                            Text(file.path)
                        }
                        
                        .padding()
                        .background(.gray.opacity(0.4))
                        .hoverEffect(.lift)
                        .clipShape(.rect(cornerSize: CGSize(width: 35, height: 35)))
                        .padding(.horizontal)
                        
                    }
                }
            }
        }
        .onAppear() {
            self.becomeFirstResponder = true
        }
//        .background(.white)
    }
}

#Preview {
    QuickOpenView(state: QuickOpenViewState(query: "H", files: [
        File(path: "h.txt"),
        File(path: "hello.go"),
        File(path: "hit.go")
    ]))
}


