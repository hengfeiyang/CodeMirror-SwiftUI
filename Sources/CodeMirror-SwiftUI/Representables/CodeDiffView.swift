//
//  CodeDiffView.swift
//  
//
//  Created by Claude Code on 8/22/25.
//

import Foundation
import SwiftUI
import WebKit

#if os(OSX)
typealias DiffRepresentableView = NSViewRepresentable
#elseif os(iOS)
typealias DiffRepresentableView = UIViewRepresentable
#endif

// MARK: - CodeDiffView

public struct CodeDiffView: DiffRepresentableView {
    
    var originalCode: String
    var modifiedCode: String
    var theme: CodeViewTheme
    var mode: Mode
    var fontSize: Int
    var showLineNumbers: Bool
    var collapseIdentical: Bool
    var allowEdit: Bool
    
    var onLoadSuccess: (() -> ())?
    var onLoadFail: ((Error) -> ())?
    var onCoordinatorReady: ((CodeDiffViewController) -> ())?
    
    public init(originalCode: String,
                modifiedCode: String,
                theme: CodeViewTheme = CodeViewTheme.materialPalenight,
                mode: Mode = CodeMode.swift.mode(),
                fontSize: Int = 12,
                showLineNumbers: Bool = true,
                collapseIdentical: Bool = false,
                allowEdit: Bool = false
    ) {
        self.originalCode = originalCode
        self.modifiedCode = modifiedCode
        self.theme = theme
        self.mode = mode
        self.fontSize = fontSize
        self.showLineNumbers = showLineNumbers
        self.collapseIdentical = collapseIdentical
        self.allowEdit = allowEdit
    }
    
    // MARK: - Life Cycle
    
    #if os(OSX)
    public func makeNSView(context: Context) -> WKWebView {
        createWebView(context)
    }
    #elseif os(iOS)
    public func makeUIView(context: Context) -> WKWebView {
        createWebView(context)
    }
    #endif
    
    #if os(OSX)
    public func updateNSView(_ webView: WKWebView, context: Context) {
        updateWebView(context)
    }
    #elseif os(iOS)
    public func updateUIView(_ webView: WKWebView, context: Context) {
        updateWebView(context)
    }
    #endif
    
    public func makeCoordinator() -> CodeDiffViewController {
        let coordinator = CodeDiffViewController(self)
        onCoordinatorReady?(coordinator)
        return coordinator
    }
}

// MARK: - Public API

extension CodeDiffView {
    
    public func onLoadSuccess(_ action: @escaping (() -> ())) -> Self {
        var copy = self
        copy.onLoadSuccess = action
        return copy
    }
    
    public func onLoadFail(_ action: @escaping ((Error) -> ())) -> Self {
        var copy = self
        copy.onLoadFail = action
        return copy
    }
    
    public func onCoordinatorReady(_ action: @escaping (CodeDiffViewController) -> Void) -> Self {
        var copy = self
        copy.onCoordinatorReady = action
        return copy
    }
}

// MARK: - Private API

extension CodeDiffView {
    
    private func createWebView(_ context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let userController = WKUserContentController()
        userController.add(context.coordinator, name: CodeDiffViewRPC.isReady)
        userController.add(context.coordinator, name: CodeDiffViewRPC.textContentDidChange)
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        #if os(OSX)
        webView.setValue(true, forKey: "drawsTransparentBackground")
        webView.allowsMagnification = false
        #elseif os(iOS)
        webView.isOpaque = false
        #endif
        
        let codeMirrorBundle = try! Bundle.codeMirrorBundle()
        guard let diffHtmlPath = codeMirrorBundle.path(forResource: "diff", ofType: "html") else {
            fatalError("Diff HTML file is missing")
        }
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: diffHtmlPath))
        
        webView.load(data, mimeType: "text/html", characterEncodingName: "utf-8", baseURL: codeMirrorBundle.resourceURL!)
        
        context.coordinator.setWebView(webView)
        context.coordinator.setThemeName(theme.rawValue)
        context.coordinator.setMimeType(mode.mimeType)
        context.coordinator.setOriginalCode(originalCode)
        context.coordinator.setModifiedCode(modifiedCode)
        context.coordinator.setFontSize(fontSize)
        context.coordinator.setShowLineNumbers(showLineNumbers)
        context.coordinator.setCollapseIdentical(collapseIdentical)
        context.coordinator.setAllowEdit(allowEdit)
        
        return webView
    }
    
    private func updateWebView(_ context: CodeDiffView.Context) {
        context.coordinator.setThemeName(theme.rawValue)
        context.coordinator.setMimeType(mode.mimeType)
        context.coordinator.setOriginalCode(originalCode)
        context.coordinator.setModifiedCode(modifiedCode)
        context.coordinator.setFontSize(fontSize)
        context.coordinator.setShowLineNumbers(showLineNumbers)
        context.coordinator.setCollapseIdentical(collapseIdentical)
        context.coordinator.setAllowEdit(allowEdit)
    }
}