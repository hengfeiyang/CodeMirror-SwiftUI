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
  @State private var leftContent = """
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
  
  @State private var rightContent = """
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

  // Copy original content (left side) to clipboard
  private func copyLeftToClipboard() {
    print("Copy Left button clicked")
    print("Current diffCoordinator state: \(diffCoordinator != nil ? "available" : "nil")")
    print("Current tab selection: \(selectedTheme)")
    
    guard let coordinator = diffCoordinator else {
      print("Diff coordinator not available")
      return
    }
    
    print("Coordinator found, calling getLeftContent...")
    coordinator.getLeftContent { content in
      print("Left content received, length: \(content.count)")
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(content, forType: .string)
      
      // Provide visual feedback
      DispatchQueue.main.async {
        copyLeftButtonText = "Copied!"
        print("Left content copied to clipboard!")
        
        // Reset button text after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          copyLeftButtonText = "Copy Left"
        }
      }
    }
  }
  
  // Copy modified content (right side) to clipboard
  private func copyRightToClipboard() {
    print("Copy Right button clicked")
    print("Current diffCoordinator state: \(diffCoordinator != nil ? "available" : "nil")")
    print("Current tab selection: \(selectedTheme)")
    
    guard let coordinator = diffCoordinator else {
      print("Diff coordinator not available")
      return
    }
    
    print("Coordinator found, calling getRightContent...")
    coordinator.getRightContent { content in
      print("Right content received, length: \(content.count)")
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(content, forType: .string)
      
      // Provide visual feedback
      DispatchQueue.main.async {
        copyRightButtonText = "Copied!"
        print("Right content copied to clipboard!")
        
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
            ForEach(themes.indices, id: \.self) { index in
              Text(self.themes[index].rawValue)
            }
          }
          .frame(minWidth: 100, idealWidth: 150, maxWidth: 150)
          
          Spacer()
          
          Button(action: { lineWrapping.toggle() }) { Text("Wrap") }
                    
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
            CodeView(
                     code: $codeBlock,
                     mode: codeMode,
                     theme: themes[selectedTheme],
                     fontSize: fontSize,
                     showInvisibleCharacters: showInvisibleCharacters,
                     lineWrapping: lineWrapping)
              .onLoadSuccess {
                print("CodeView Loaded")
              }
              .onContentChange { _ in
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
            ForEach(themes.indices, id: \.self) { index in
              Text(self.themes[index].rawValue)
            }
          }
          .frame(minWidth: 100, idealWidth: 150, maxWidth: 150)
          
          Spacer()
          
          Button(action: copyLeftToClipboard) { 
            Text(copyLeftButtonText)
          }
          
          Button(action: copyRightToClipboard) { 
            Text(copyRightButtonText)
          }
          
          Toggle(isOn: $showInvisibleCharacters) {
            Text("Show invisible chars.")
          }
          .padding(.trailing, 8)
          
          Button(action: { lineWrapping.toggle() }) { Text("Wrap") }
            
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
          leftContent: $leftContent,
          rightContent: $rightContent,
          mode: CodeMode.javascript.mode(),
          theme: themes[selectedTheme],
          fontSize: fontSize,
          showInvisibleCharacters: showInvisibleCharacters,
          lineWrapping: lineWrapping,
          readOnly: false
        )
        .onLoadSuccess {
          print("CodeDiffView Loaded")
        }
        .onContentChange { _ in
          print("CodeDiffView Content Changed")
        }
        .onLoadFail { error in
          print("CodeDiffView Load failed : \(error.localizedDescription)")
        }
        .onCoordinatorReady { coordinator in
          // Store the coordinator for copy functionality
          print("CodeDiffView onCoordinatorReady called, setting diffCoordinator...")
          
          // Use the helper function to set the coordinator
          DispatchQueue.main.async {
            self.diffCoordinator = coordinator
            print("CodeDiffView diffCoordinator set successfully")
          }

          // Demonstrate the new consistent API functions
          print("CodeDiffView Coordinator Ready")
          
          // Test some of the new API functions after a short delay
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("CodeDiffView Testing coordinator functions after 2 second delay...")
            
            coordinator.isClean { clean in
              print("CodeDiffView Content is clean: \(clean)")
            }
            
            // Test the copy functions
            coordinator.getLeftContent { content in
              print("CodeDiffView Test getLeftContent: \(content.prefix(50))...")
            }
            
            coordinator.getRightContent { content in
              print("CodeDiffView Test getRightContent: \(content.prefix(50))...")
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
