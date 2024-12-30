//
//  UIKit+SwiftUI.swift
//  
//
//  Created by Reid Chatham on 11/17/24.
//

import SwiftUI
import UIKit


extension View {
    var hostingController: UIViewController {
        UIHostingController(rootView: self)
    }
}

