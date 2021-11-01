//
//  AutocompletionPanel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 01.11.2021.
//

import SwiftUI
import DependencyInjection

@MainActor
final class AutocompletionModel: ObservableObject {
    
    @Autowired(cacheType: .share) private var dao: DAOProtocol
    @Published var suggestions: [String] = []
    
    func updateSuggestions(mode: AutocompletionPanel.Mode) {
        Task {
            switch mode {
            case .good:
                suggestions = try await dao.getGoods().map({ $0.name })
            case .store:
                suggestions = try await dao.getStores().map({ $0.name })
            case .category:
                suggestions = try await dao.getCategories().map({ $0.name })
            }
        }
    }
}

struct AutocompletionPanel: View {
    
    enum Mode {
        case good
        case store
        case category
    }
    
    @Environment(\.presentationMode) var presentation
    @Binding var textInput: String
    @StateObject private var model = AutocompletionModel()
    private let mode: Mode
    
    init(textInput: Binding<String>, mode: Mode) {
        _textInput = textInput
        self.mode = mode
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Input", text: $textInput).textFieldStyle(.roundedBorder)
                Button(action: {
                    presentation.wrappedValue.dismiss()
                }, label: { Text("Done") })
            }
            List {
                ForEach(model.suggestions.filter({
                    textInput.isEmpty || $0.lowercased().contains(textInput.lowercased())
                }), id: \.self) { element in
                    HStack {
                        Text(element)
                        Spacer()
                    }.contentShape(Rectangle())
                        .listRowBackground(Color("backgroundColor")).onTapGesture {
                            textInput = element
                            presentation.wrappedValue.dismiss()
                        }
                }
            }.listStyle(.plain)
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                model.updateSuggestions(mode: mode)
            })
    }
}

struct AutocompletionPanel_Previews: PreviewProvider {
    @State static var text: String = ""
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(AutocompletionPanel(textInput: $text, mode: .good))
    }
}
