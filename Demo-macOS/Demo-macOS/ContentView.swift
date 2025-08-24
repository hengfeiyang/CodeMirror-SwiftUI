//
//  ContentView.swift
//  Demo-macOS
//
//  Created by Anthony Fernandez on 8/28/20.
//  Copyright © 2020 marshallino16. All rights reserved.
//

import SwiftUI
import AppKit
import CodeMirror_SwiftUI

struct ContentView: View {
  
  @State private var codeBlock = try! String(contentsOf: Bundle.main.url(forResource: "Demo", withExtension: "txt")!)
  @State private var codeMode = CodeMode.swift.mode()
  @State private var selectedTheme = 0
  @State private var fontSize = 12
  @State private var showInvisibleCharacters = true
  @State private var lineWrapping = true
  @State private var copyButtonText = "Copy"
  @State private var copyLeftButtonText = "Copy Left"
  @State private var copyRightButtonText = "Copy Right"
  @State private var diffCoordinator: CodeDiffViewController?
  
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
  
  // Copy to clipboard function
  private func copyToClipboard() {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(codeBlock, forType: .string)
    
    // Provide visual feedback
    copyButtonText = "Copied!"
    print("Code copied to clipboard!")
    
    // Reset button text after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      copyButtonText = "Copy"
    }
  }
  
  // Copy diff content to clipboard function
  private func copyDiffToClipboard() {
    guard let coordinator = diffCoordinator else {
      print("Diff coordinator not available")
      return
    }
    
    coordinator.getContent { content in
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(content, forType: .string)
      
      // Provide visual feedback
      DispatchQueue.main.async {
        copyRightButtonText = "Copied!"
        print("Modified content copied to clipboard!")
        
        // Reset button text after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          copyRightButtonText = "Copy Right"
        }
      }
    }
  }
  
  var body: some View {
    TabView {
      // Regular Code Editor Tab
      VStack {
        HStack {
          Picker(selection: $selectedTheme, label: EmptyView()) {
            ForEach(0 ..< themes.count) {
              Text(self.themes[$0].rawValue)
            }
          }
          .frame(minWidth: 100, idealWidth: 150, maxWidth: 150)
          
          Spacer()
          
          Button(action: { lineWrapping.toggle() }) { Text("Wrap") }
          
          Button(action: copyToClipboard) { Text(copyButtonText) }
          
          Toggle(isOn: $showInvisibleCharacters) {
            Text("Show invisible chars.")
          }
          .padding(.trailing, 8)
          
          Text("Font Size")
          
          Button(action: { fontSize -= 1}) {
            Image("minus")
              .resizable()
              .scaledToFit()
            
          }
          .frame(width: 20, height: 20)
          
          Button(action: { fontSize += 1}) {
            Image("plus")
              .resizable()
              .scaledToFit()
          }
          .frame(width: 20, height: 20)
        }
        .padding()
        
        GeometryReader { reader in
          ScrollView {
            CodeView(theme: themes[selectedTheme],
                     code: $codeBlock,
                     mode: codeMode,
                     fontSize: fontSize,
                     showInvisibleCharacters: showInvisibleCharacters,
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
              .frame(height: reader.size.height)
              .tag(1)
          }.frame(height: reader.size.height)
        }
      }
      .tabItem {
        Image(systemName: "doc.text")
        Text("Editor")
      }
      
      // Code Diff Tab
      VStack {
        HStack {
          Picker(selection: $selectedTheme, label: EmptyView()) {
            ForEach(0 ..< themes.count) {
              Text(self.themes[$0].rawValue)
            }
          }
          .frame(minWidth: 100, idealWidth: 150, maxWidth: 150)
          
          Spacer()
          
          Button(action: copyDiffToClipboard) { 
            Text(copyLeftButtonText)
          }
          
          Button(action: copyDiffToClipboard) { 
            Text(copyRightButtonText)
          }
            
            Text("Font Size")
            
            Button(action: { fontSize -= 1}) {
              Image("minus")
                .resizable()
                .scaledToFit()
              
            }
            .frame(width: 20, height: 20)
            
            Button(action: { fontSize += 1}) {
              Image("plus")
                .resizable()
                .scaledToFit()
            }
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
        .onCoordinatorReady { coordinator in
          // Store the coordinator for copy functionality
          self.diffCoordinator = coordinator
          
          // Demonstrate the new consistent API functions
          print("CodeDiffView Coordinator Ready")
          
          // Test some of the new API functions after a short delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            coordinator.getSupportedMimeTypes { mimeTypes in
              print("Supported MIME types: \(mimeTypes)")
            }
            
            coordinator.getContent { content in
              print("Current content length: \(content.count) characters")
            }
            
            coordinator.isClean { clean in
              print("Content is clean: \(clean)")
            }
          }
        }
      }
      .tabItem {
        Image(systemName: "doc.on.doc")
        Text("Diff")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
