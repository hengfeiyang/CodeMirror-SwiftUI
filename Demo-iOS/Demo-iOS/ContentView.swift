//
//  ContentView.swift
//  Demo-iOS
//
//  Created by Anthony Fernandez on 8/31/20.
//

import SwiftUI
import CodeMirror_SwiftUI

struct ContentView: View {
  
  @State private var codeBlock = try! String(contentsOf: Bundle.main.url(forResource: "Demo", withExtension: "txt")!)
  @State private var codeMode = CodeMode.swift.mode()
  @State private var selectedTheme = 0
  @State private var fontSize = 12
  @State private var lineWrapping = true
  
  private var themes = CodeViewTheme.allCases.sorted {
    return $0.rawValue < $1.rawValue
  }
  
  // Sample code for diff demonstration
  private let originalCode = """
function calculateTotal(items) {
  let total = 0;
  for (let item of items) {
    total += item.price;
  }
  return total;
}

const products = [
  { name: "Laptop", price: 999 },
  { name: "Mouse", price: 25 },
  { name: "Keyboard", price: 75 }
];

console.log("Total:", calculateTotal(products));
"""
  
  private let modifiedCode = """
function calculateTotal(items) {
  let total = 0;
  let tax = 0;
  for (let item of items) {
    total += item.price;
    tax += item.price * 0.08; // Add 8% tax
  }
  return { total, tax, grandTotal: total + tax };
}

const products = [
  { name: "Laptop", price: 999 },
  { name: "Mouse", price: 25 },
  { name: "Keyboard", price: 75 },
  { name: "Monitor", price: 299 } // New item
];

const result = calculateTotal(products);
console.log("Total:", result.total);
console.log("Tax:", result.tax);
console.log("Grand Total:", result.grandTotal);
"""
  
  var body: some View {
    TabView {
      // Regular Code Editor Tab
      VStack {
        HStack {
          Picker(selection: $selectedTheme, label: Text("CodeView Theme")) {
            ForEach(0 ..< themes.count) {
              Text(self.themes[$0].rawValue)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .frame(minWidth: 100, idealWidth: 150, maxWidth: 150)

          Spacer()

          Button(action: { lineWrapping.toggle() }) { Text("Wrap") }
          
          Spacer()
          
          Text("Font Size")
          
          Button(action: { fontSize -= 1}) {
            Image("minus")
              .resizable()
              .renderingMode(.template)
              .foregroundColor(.black)
              .scaledToFit()
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 20, height: 20)
          
          Button(action: { fontSize += 1}) {
            Image("plus")
              .resizable()
              .renderingMode(.template)
              .foregroundColor(.black)
              .scaledToFit()
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 20, height: 20)
        }
        .padding()
        
        CodeView(theme: themes[selectedTheme],
                 code: $codeBlock,
                 mode: codeMode,
                 fontSize: fontSize,
                 lineWrapping: lineWrapping)
          .onLoadSuccess {
            print("CodeView Loaded")
          }
          .onContentChange { newCode in
            print("CodeView Content Changed")
          }
          .onLoadFail { error in
            print("CodeView Load failed : \(error.localizedDescription)")
          }
      }
      .tabItem {
        Image(systemName: "doc.text")
        Text("Editor")
      }
      
      // Code Diff Tab
      VStack {
        HStack {
          Text("Code Diff View")
            .font(.headline)
          
          Spacer()
          
          Picker(selection: $selectedTheme, label: Text("Theme")) {
            ForEach(0 ..< themes.count) {
              Text(self.themes[$0].rawValue)
            }
          }
          .pickerStyle(MenuPickerStyle())
          .frame(minWidth: 100, idealWidth: 150, maxWidth: 150)
          
          Text("Font Size")
          
          Button(action: { fontSize -= 1}) {
            Image("minus")
              .resizable()
              .renderingMode(.template)
              .foregroundColor(.black)
              .scaledToFit()
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 20, height: 20)
          
          Button(action: { fontSize += 1}) {
            Image("plus")
              .resizable()
              .renderingMode(.template)
              .foregroundColor(.black)
              .scaledToFit()
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 20, height: 20)
        }
        .padding()
        
        CodeDiffView(
          originalCode: originalCode,
          modifiedCode: modifiedCode,
          theme: themes[selectedTheme],
          mode: CodeMode.javascript.mode(),
          fontSize: fontSize,
          showLineNumbers: true,
          collapseIdentical: false,
          allowEdit: true
        )
        .onLoadSuccess {
          print("CodeDiffView Loaded")
        }
        .onLoadFail { error in
          print("CodeDiffView Load failed : \(error.localizedDescription)")
        }
      }
      .tabItem {
        Image(systemName: "doc.on.doc")
        Text("Diff")
      }
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
