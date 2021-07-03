//
//  ShareViewController.swift
//  MyShareExtension
//
//  Created by Sergey Mikhno on 03.07.21.
//

import UIKit
import Social
import MobileCoreServices


class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        print("isContentValid")
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
                return
            }

        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
                    for itemProvider in itemProviders {
                        if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {

                            itemProvider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil, completionHandler: { text, error in
                                print(text!)
                                
                                let defaults = UserDefaults(suiteName: "group.org.youtubeplayer.group")!
                                
                                defaults.setValue(text!, forKey: "mykey")
                                
                            })
                        }
                    }
                }
        }
        //self.extensionContext!.completeRequest(returningItems: extensionItems, completionHandler: nil)
        
        redirectToHostApp()
        
        
       // [self.navigationController, present:vc animated:YES completion:nil] as [Any];
        
    }
    
    func redirectToHostApp() {
            let url = URL(string: "myapp://com.youtubeplayer.myapp")
            var responder = self as UIResponder?
            let selectorOpenURL = sel_registerName("openURL:")
            
            while (responder != nil) {
                if (responder?.responds(to: selectorOpenURL))! {
                    let _ = responder?.perform(selectorOpenURL, with: url)
                }
                responder = responder!.next
            }
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        print("configurationItems")
        return []
    }
    

}
