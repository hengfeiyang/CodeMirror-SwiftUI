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
        self.webView = webView
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
            if let content = message.body as? String {
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
    
    func setThemeName(_ theme: String) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffTheme('\(theme)')") { _, _ in }
    }
    
    func setMimeType(_ mimeType: String) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffMimeType('\(mimeType)')") { _, _ in }
    }
    
    func setOriginalCode(_ code: String) {
        guard let webView = webView else { return }
        let escapedCode = code.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
                             .replacingOccurrences(of: "\r", with: "\\r")
        webView.evaluateJavaScript("SetOriginalCode('\(escapedCode)')") { _, _ in }
    }
    
    func setModifiedCode(_ code: String) {
        guard let webView = webView else { return }
        let escapedCode = code.replacingOccurrences(of: "\\", with: "\\\\")
                             .replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
                             .replacingOccurrences(of: "\r", with: "\\r")
        webView.evaluateJavaScript("SetModifiedCode('\(escapedCode)')") { _, _ in }
    }
    
    func setFontSize(_ fontSize: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffFontSize(\(fontSize))") { _, _ in }
    }
    
    func setShowLineNumbers(_ show: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetDiffLineNumbers(\(show))") { _, _ in }
    }
    
    func setCollapseIdentical(_ collapse: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetCollapseIdentical(\(collapse))") { _, _ in }
    }
    
    func setAllowEdit(_ allowEdit: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetAllowEdit(\(allowEdit))") { _, _ in }
    }
    
    func refreshDiffView() {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("RefreshDiffView()") { _, _ in }
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
    
    public func setLineWrapping(_ wrapping: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetLineWrapping(\(wrapping))") { _, _ in }
    }
    
    public func getLineWrapping(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetLineWrapping()") { result, _ in
            if let wrapping = result as? Bool {
                completion(wrapping)
            }
        }
    }
    
    public func setReadOnly(_ readOnly: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetReadOnly(\(readOnly))") { _, _ in }
    }
    
    public func getReadOnly(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetReadOnly()") { result, _ in
            if let readOnly = result as? Bool {
                completion(readOnly)
            }
        }
    }
    
    public func setIndentUnit(_ unit: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetIndentUnit(\(unit))") { _, _ in }
    }
    
    public func getIndentUnit(completion: @escaping (Int) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetIndentUnit()") { result, _ in
            if let unit = result as? Int {
                completion(unit)
            }
        }
    }
    
    public func setTheme(_ theme: String) {
        setThemeName(theme)
    }
    
    public func toggleInvisible(_ toggle: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("ToggleInvisible(\(toggle))") { _, _ in }
    }
    
    public func setTabSize(_ size: Int) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetTabSize(\(size))") { _, _ in }
    }
    
    public func getTabSize(completion: @escaping (Int) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetTabSize()") { result, _ in
            if let size = result as? Int {
                completion(size)
            }
        }
    }
    
    public func setTabInsertSpaces(_ flag: Bool) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("SetTabInsertSpaces(\(flag))") { _, _ in }
    }
    
    public func getTabInsertSpaces(completion: @escaping (Bool) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetTabInsertSpaces()") { result, _ in
            if let flag = result as? Bool {
                completion(flag)
            }
        }
    }
    
    public func setContent(_ content: String) {
        guard let webView = webView else { return }
        let hexContent = content.data(using: .utf8)?.map { String(format: "%02x", $0) }.joined() ?? ""
        webView.evaluateJavaScript("SetContent('\(hexContent)')") { _, _ in }
    }
    
    public func getContent(completion: @escaping (String) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetContent()") { result, _ in
            if let content = result as? String {
                completion(content)
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
    
    public func getTextSelection(completion: @escaping (String) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("GetTextSelection()") { result, _ in
            if let selection = result as? String {
                completion(selection)
            }
        }
    }
    
    // setFontSize is already defined above as setFontSize
    
    public func validateJSON(completion: @escaping (String) -> Void) {
        guard let webView = webView else { return }
        webView.evaluateJavaScript("ValidateJSON()") { result, _ in
            if let errorMessage = result as? String {
                completion(errorMessage)
            }
        }
    }
}