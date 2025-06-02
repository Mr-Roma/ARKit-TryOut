//
//  EditMode.swift
//  project1
//
//  Created by Melki Jonathan Andara on 02/06/25.
//

import Foundation

#if os(iOS)
enum EditMode {
    case move
    case resize
    case rotate
    case opacity
    case wrap
}
#else
enum EditMode {
    case move
    case resize
    case rotate
    case opacity
    case wrap
}
#endif 