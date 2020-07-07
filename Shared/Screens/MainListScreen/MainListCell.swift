//
//  MainListCell.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 7/4/20.
//

import SwiftUI

struct MainListCell: View {
	let listName: String
	let isCompleted: Bool
	let isRemote: Bool

    var body: some View {
		HStack {
			Image(systemName: isRemote ? "cloud" : "iphone").padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/).frame(minWidth: 40, maxWidth: 40, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
			Text(listName).padding([.trailing, .top, .bottom], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/).foregroundColor(isCompleted ? .secondary : .primary)
		}
    }
}

struct MainListCell_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			MainListCell(listName: "Test list", isCompleted: false, isRemote: true)
				.previewLayout(.sizeThatFits)
			MainListCell(listName: "Test list", isCompleted: true, isRemote: true)
				.previewLayout(.sizeThatFits)
			MainListCell(listName: "Test list", isCompleted: false, isRemote: false)
				.previewLayout(.sizeThatFits)
		}
    }
}
