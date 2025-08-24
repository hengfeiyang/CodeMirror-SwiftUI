//
//  CodeDiffViewController.swift
//  
//
//  Created by Claude Code on 8/22/25.
//

import Foundation
import WebKit

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public class CodeDiffViewController: NSObject {
    
    var parent: CodeDiffView
    var webView: WKWebView?
  
    init(_ parent: CodeDiffView) {
        self.parent = parent
    }
    
    func setWebView(_ webView: WKWebView) {
        print("CodeDiffViewController: setWebView called")
        self.webView = webView
        print("CodeDiffViewController: webView set successfully")
    }
}

// MARK: - WKNavigationDelegate

extension CodeDiffViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.onLoadSuccess?()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent.onLoadFail?(error)
    }
}

// MARK: - WKScriptMessageHandler

extension CodeDiffViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        switch message.name {
        case CodeDiffViewRPC.isReady:
            // Diff view is ready
            break
        case CodeDiffViewRPC.textContentDidChange:
            // Text content changed - can be handled by parent if needed
            if message.body is String {
                // Store or process the updated content
                // This maintains consistency with the regular CodeView behavior
            }
            break
        default:
            break
        }
    }
}

// MARK: - JavaScript Interface

extension CodeDiffViewController {
    
    func setMimeType(_ mimeType: String) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetMimeType('\(mimeType)')") { _, _ in }
    }
    
    func setLeftContent(_ value: String) {
        if let hexString = value.data(using: .utf8)?.hexEncodedString() {
            let script = """
            var content = "\(hexString)"; SetLeftContent(content);
            """
            guard let webView = webView else { return }
            webView.evaluateJavaScript(script) { _, _ in }
            }
    }
    
    func setRightContent(_ value: String) {
        if let hexString = value.data(using: .utf8)?.hexEncodedString() {
            let script = """
            var content = "\(hexString)"; SetRightContent(content);
            """
            guard let webView = webView else { return }
            webView.evaluateJavaScript(script) { _, _ in }
        }
    }
    
    func setFontSize(_ fontSize: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetFontSize(\(fontSize))") { _, _ in }
    }
    
    func setShowLineNumbers(_ show: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetLineNumbers(\(show))") { _, _ in }
    }
    
    func setCollapseIdentical(_ collapse: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetCollapseIdentical(\(collapse))") { _, _ in }
    }
    
    // MARK: - Additional API functions for consistency with regular CodeView
    
    public func getSupportedMimeTypes(completion: @escaping (String) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SupportedMimeTypes()") { result, _ in
            if let mimeTypes = result as? String {
                completion(mimeTypes)
            }
        }
    }
    
    func setLineWrapping(_ wrapping: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetLineWrapping(\(wrapping))") { _, _ in }
    }
    
    func getLineWrapping(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetLineWrapping()") { result, _ in
            if let wrapping = result as? Bool {
                completion(wrapping)
            }
        }
    }
    
    func setReadOnly(_ readOnly: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetReadOnly(\(readOnly))") { _, _ in }
    }
    
    func getReadOnly(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetReadOnly()") { result, _ in
            if let readOnly = result as? Bool {
                completion(readOnly)
            }
        }
    }
    
    func setIndentUnit(_ unit: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetIndentUnit(\(unit))") { _, _ in }
    }
    
    func getIndentUnit(completion: @escaping (Int) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetIndentUnit()") { result, _ in
            if let unit = result as? Int {
                completion(unit)
            }
        }
    }
    
    func setThemeName(_ theme: String) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetTheme('\(theme)')") { _, _ in }
    }
    
    func toggleInvisible(_ toggle: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("ToggleInvisible(\(toggle))") { _, _ in }
    }
    
    func setTabSize(_ size: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetTabSize(\(size))") { _, _ in }
    }
    
    func getTabSize(completion: @escaping (Int) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetTabSize()") { result, _ in
            if let size = result as? Int {
                completion(size)
            }
        }
    }
    
    func setTabInsertSpaces(_ flag: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetTabInsertSpaces(\(flag))") { _, _ in }
    }
    
    func getTabInsertSpaces(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetTabInsertSpaces()") { result, _ in
            if let flag = result as? Bool {
                completion(flag)
            }
        }
    }
    
    public func clearHistory() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("ClearHistory()") { _, _ in }
    }
    
    public func isClean(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("IsClean()") { result, _ in
            if let clean = result as? Bool {
                completion(clean)
            }
        }
    }
    
    func getTextSelection(completion: @escaping (String) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetTextSelection()") { result, _ in
            if let selection = result as? String {
                completion(selection)
            }
        }
    }    
    
    // MARK: - Copy functionality for diff view
    
    public func getLeftContent(completion: @escaping (String) -> Void) {
        guard let webView = webView else { 
            print("WebView not available in getLeftContent")
            return 
        }
        print("Calling GetLeftContent() JavaScript function...")
        webView.evaluateJavaScript("GetLeftContent()") { result, error in
            if let error = error {
                print("Error calling GetLeftContent(): \(error)")
                completion("")
                return
            }
            if let content = result as? String {
                print("GetLeftContent() returned: \(content.prefix(100))...")
                completion(content)
            } else {
                print("GetLeftContent() returned unexpected result type: \(String(describing: result))")
                completion("")
            }
        }
    }
    
    public func getRightContent(completion: @escaping (String) -> Void) {
        guard let webView = webView else { 
            print("WebView not available in getRightContent")
            return 
        }
        print("Calling GetRightContent() JavaScript function...")
        webView.evaluateJavaScript("GetRightContent()") { result, error in
            if let error = error {
                print("Error calling GetRightContent(): \(error)")
                completion("")
                return
            }
            if let content = result as? String {
                print("GetRightContent() returned: \(content.prefix(100))...")
                completion(content)
            } else {
                print("GetRightContent() returned unexpected result type: \(String(describing: result))")
                completion("")
            }
        }
    }
}
