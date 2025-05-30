//
//  ARManager.swift
//  project1
//
//  Created by Melki Jonathan Andara on 29/05/25.
//

import Combine
import SwiftUI

class ARManager {
    static let shared = ARManager()
    private init() { }
    
    var actionStream = PassthroughSubject<ARAction, Never>()
}

